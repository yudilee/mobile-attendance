import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'app_settings.dart';

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  const ForbiddenException(this.message);
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final Logger _logger = Logger();

  /// Returns a configured Dio instance with the current server URL and API key.
  Future<Dio> _getDio() async {
    final serverUrl = await AppSettings.getServerUrl();
    final apiKey = await AppSettings.getApiKey();

    final dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    await _configurePinning(dio);
    return dio;
  }

  /// Applies certificate pinning based on current settings.
  /// When pinning is enabled, all untrusted certificates are rejected.
  /// When disabled (default), all certificates are accepted (dev flexibility).
  Future<void> _configurePinning(Dio dio) async {
    final pinEnabled = await AppSettings.isCertificatePinEnabled();
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
          // When pinning is enabled, reject untrusted certs (strict)
          // When disabled, allow all (dev mode)
          return !pinEnabled;
        };
        return client;
      };
    }
  }

  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final errorMsg = (e.response?.data is Map ? e.response?.data['detail'] : null)
        ?? e.message
        ?? 'Network error';

    if (statusCode == 401) {
      throw AuthenticationException(errorMsg);
    } else if (statusCode == 403) {
      throw ForbiddenException(errorMsg);
    } else if (statusCode != null && statusCode >= 500) {
      throw ServerException(errorMsg);
    } else if (_isNetworkError(e)) {
      throw NetworkException(errorMsg);
    }
    throw Exception(errorMsg);
  }

  /// Submit a single attendance punch.
  Future<Map<String, dynamic>> submitPunch({
    String? employeeId,
    required String deviceUuid,
    required double lat,
    required double lon,
    required bool isMocked,
    required bool biometricVerified,
    required String punchType,
    required String timestamp,
    int tzOffsetMinutes = 420,
    bool gpsValidated = false,
    String? clientPunchId,
  }) async {
    final dio = await _getDio();
    try {
      _logger.i('Submitting punch: $punchType for $employeeId');
      final response = await dio.post('/api/v1/punch', data: {
        if (employeeId != null) 'employee_id': employeeId,
        'device_uuid': deviceUuid,
        'latitude': lat,
        'longitude': lon,
        'is_mock_location': isMocked,
        'biometric_verified': biometricVerified,
        'punch_type': punchType,
        'timestamp': timestamp,
        'tz_offset_minutes': tzOffsetMinutes,
        'gps_time_validated': gpsValidated,
        if (clientPunchId != null) 'client_punch_id': clientPunchId,
      });
      _logger.i('Punch success: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Punch failed: ${e.message}');
      _handleDioError(e);
    }
  }

  /// Submit a batch of offline punches in one request.
  /// Returns a list of results — one per punch in the same order.
  Future<List<Map<String, dynamic>>> submitBatch(
    List<Map<String, dynamic>> punches,
  ) async {
    final dio = await _getDio();
    try {
      _logger.i('Submitting batch of ${punches.length} punches');
      final response = await dio.post('/api/v1/punch/batch', data: {
        'punches': punches,
      });
      final results = (response.data['results'] as List)
          .cast<Map<String, dynamic>>();
      _logger.i('Batch sync done: ${response.data['synced']} synced, ${response.data['failed']} failed');
      return results;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Fetch branch assignment and geofence config for this device.

  Future<Map<String, dynamic>> onboardDevice({
    String? token,
    String? employeeId,
    required String deviceUuid,
    String? deviceLabel,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.post(
        '/api/v1/device-onboard',
        data: {
          if (token != null && token.isNotEmpty) 'token': token,
          if (employeeId != null && employeeId.isNotEmpty) 'employee_id': employeeId,
          'device_uuid': deviceUuid,
          if (deviceLabel != null) 'device_label': deviceLabel,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getDeviceConfig({
    String? employeeId,
    required String deviceUuid,
    String? deviceLabel,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/device-config', queryParameters: {
        if (employeeId != null) 'employee_id': employeeId,
        'device_uuid': deviceUuid,
        if (deviceLabel != null) 'device_label': deviceLabel,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Fetch available punch types from server.
  Future<List<Map<String, dynamic>>> getPunchTypes() async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/punch-types');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Test connection & fetch device diagnostics from server.
  Future<Map<String, dynamic>> getDeviceDiagnostics({
    required String deviceUuid,
    String? employeeId,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/device/diagnostics', queryParameters: {
        'device_uuid': deviceUuid,
        if (employeeId != null) 'employee_id': employeeId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.unknown;

  /// Register/update the FCM push notification token on the backend.
  Future<void> updateFcmToken(String deviceUuid, String fcmToken) async {
    final dio = await _getDio();
    try {
      await dio.post('/api/v1/device/fcm-token', data: {
        'device_uuid': deviceUuid,
        'fcm_token': fcmToken,
      });
      _logger.i('FCM token updated on server.');
    } on DioException catch (e) {
      // Silently fail — token registration is non-critical
      _logger.w('Failed to update FCM token: ${e.message}');
    }
  }

  /// Fetch punch logs history for this employee from server.
  Future<List<Map<String, dynamic>>> getPunchHistory({
    String? employeeId,
    int limit = 50,
    int offset = 0,
  }) async {
    final dio = await _getDio();
    try {
      _logger.i('Fetching punch history from server for $employeeId');
      final response = await dio.get('/api/v1/punch-history', queryParameters: {
        if (employeeId != null) 'employee_id': employeeId,
        'limit': limit,
        'offset': offset,
      });
      final data = response.data['data'] as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map ? e.response?.data['detail'] : null)
          ?? e.message
          ?? 'Network error';
      _logger.e('Failed to fetch punch history: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Checks the required app version from the server.
  Future<Map<String, dynamic>> checkAppStatus() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/api/v1/app-status');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to check app status: $e');
      return {'status': 'error'};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FIELD OPERATIONS APIS (Mechanic Storing & Sales Canvassing)
  // ══════════════════════════════════════════════════════════════════════════════

  /// Start a field visit (storing, canvassing, delivery, service)
  Future<Map<String, dynamic>> checkInFieldVisit({
    required String employeeId,
    int? customerId,
    required String visitType,
    String? purpose,
    required double latitude,
    required double longitude,
    String? deviceUuid,
    bool isMockLocation = false,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.post('/api/v1/field-visit/check-in', data: {
        'employee_id': employeeId,
        if (customerId != null) 'customer_id': customerId,
        'visit_type': visitType,
        if (purpose != null) 'purpose': purpose,
        'latitude': latitude,
        'longitude': longitude,
        if (deviceUuid != null) 'device_uuid': deviceUuid,
        'is_mock_location': isMockLocation,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Complete a field visit with outcome notes
  Future<Map<String, dynamic>> checkOutFieldVisit({
    required int visitId,
    required double latitude,
    required double longitude,
    String? notes,
    String? result,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.post('/api/v1/field-visit/check-out', data: {
        'visit_id': visitId,
        'latitude': latitude,
        'longitude': longitude,
        if (notes != null) 'notes': notes,
        if (result != null) 'result': result,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Upload photo evidence for a visit
  Future<Map<String, dynamic>> uploadVisitPhoto({
    required int visitId,
    required String filePath,
    String? caption,
    String photoType = 'evidence',
    double? latitude,
    double? longitude,
  }) async {
    final dio = await _getDio();
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
        if (caption != null) 'caption': caption,
        'photo_type': photoType,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      final response = await dio.post(
        '/api/v1/field-visit/$visitId/photo',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Fetch active customer / dealer list
  Future<List<dynamic>> getCustomers({String? search, String? type, String? employeeId}) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/customers', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null && type.isNotEmpty) 'type': type,
        if (employeeId != null) 'employee_id': employeeId,
      });
      return response.data['customers'] as List<dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Fetch today's sales canvassing plan
  Future<Map<String, dynamic>> getTodayCanvassPlan(String employeeId) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/canvass-plan/today', queryParameters: {
        'employee_id': employeeId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Fetch assigned field tasks for this employee
  Future<List<dynamic>> getFieldTasks({required String employeeId, String? status}) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/field-tasks', queryParameters: {
        'employee_id': employeeId,
        if (status != null) 'status': status,
      });
      return response.data['tasks'] as List<dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Start a task
  Future<void> startFieldTask(int taskId) async {
    final dio = await _getDio();
    try {
      await dio.post('/api/v1/field-tasks/$taskId/start');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Complete a task
  Future<void> completeFieldTask(int taskId, {String? notes, int? fieldVisitId}) async {
    final dio = await _getDio();
    try {
      await dio.post('/api/v1/field-tasks/$taskId/complete', data: {
        if (notes != null) 'completed_notes': notes,
        if (fieldVisitId != null) 'field_visit_id': fieldVisitId,
      });
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Send a single or batch of GPS breadcrumbs for an active visit
  Future<void> sendBreadcrumb({
    required int visitId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
    double? heading,
    DateTime? recordedAt,
  }) async {
    final dio = await _getDio();
    try {
      await dio.post('/api/v1/field-visit/$visitId/breadcrumbs', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        if (heading != null) 'heading': heading,
        'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
      });
    } on DioException catch (e) {
      // Background breadcrumb errors are non-blocking
      _logger.w('Failed to upload breadcrumb waypoint: ${e.message}');
    }
  }

  /// Batch upload multiple offline stored breadcrumbs
  Future<void> sendBreadcrumbsBatch({
    required int visitId,
    required List<Map<String, dynamic>> breadcrumbs,
  }) async {
    if (breadcrumbs.isEmpty) return;
    final dio = await _getDio();
    try {
      await dio.post('/api/v1/field-visit/$visitId/breadcrumbs', data: {
        'breadcrumbs': breadcrumbs,
      });
    } on DioException catch (e) {
      _logger.w('Failed to upload batch breadcrumbs: ${e.message}');
    }
  }

  // --------------------------------------------------------------------------
  // LEAVE & PERMIT REQUESTS
  // --------------------------------------------------------------------------

  /// Get Leave Quota and Balance for an employee
  Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/leaves/balance', queryParameters: {
        'employee_id': employeeId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Get request history (leaves and permits) for an employee
  Future<List<Map<String, dynamic>>> getLeaveHistory(String employeeId, {String? category}) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/leaves/history', queryParameters: {
        'employee_id': employeeId,
        if (category != null) 'category': category,
      });
      final list = response.data['requests'] as List? ?? [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Submit a Leave or Late Arrival Permit Request
  Future<Map<String, dynamic>> submitLeaveOrPermitRequest({
    required String employeeId,
    required String category, // 'leave' or 'permit'
    String? leaveType, // 'annual', 'sick', 'unpaid', 'maternity', 'special'
    String? permitType, // 'late_arrival', 'early_departure', 'official_duty', 'other'
    required DateTime startDate,
    DateTime? endDate,
    String? expectedTime, // '09:30'
    required String reason,
    String? attachmentFilePath,
  }) async {
    final dio = await _getDio();
    try {
      final mapData = <String, dynamic>{
        'employee_id': employeeId,
        'category': category,
        if (leaveType != null) 'leave_type': leaveType,
        if (permitType != null) 'permit_type': permitType,
        'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T').first,
        if (expectedTime != null) 'expected_time': expectedTime,
        'reason': reason,
      };

      if (attachmentFilePath != null) {
        mapData['attachment'] = await MultipartFile.fromFile(attachmentFilePath);
      }

      final formData = FormData.fromMap(mapData);
      final response = await dio.post('/api/v1/leaves/request', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }
}
