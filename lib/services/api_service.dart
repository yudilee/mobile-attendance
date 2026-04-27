import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'app_settings.dart';

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final Logger _logger = Logger();

  /// Returns a configured Dio instance with the current server URL and API key.
  Future<Dio> _getDio() async {
    final serverUrl = await AppSettings.getServerUrl();
    final apiKey = await AppSettings.getApiKey();

    return Dio(BaseOptions(
      baseUrl: serverUrl,
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  /// Submit a single attendance punch.
  Future<Map<String, dynamic>> submitPunch({
    required String employeeId,
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
        'employee_id': employeeId,
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
      final errorMsg = (e.response?.data is Map ? e.response?.data['detail'] : null)
          ?? e.message
          ?? 'Network error';
      _logger.e('Punch failed: $errorMsg');
      if (_isNetworkError(e)) throw NetworkException(errorMsg);
      throw Exception(errorMsg);
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
      final errorMsg = (e.response?.data is Map ? e.response?.data['detail'] : null)
          ?? e.message
          ?? 'Network error';
      if (_isNetworkError(e)) throw NetworkException(errorMsg);
      throw Exception(errorMsg);
    }
  }

  /// Fetch branch assignment and geofence config for this device.
  Future<Map<String, dynamic>> getDeviceConfig({
    required String employeeId,
    required String deviceUuid,
    String? deviceLabel,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/device-config', queryParameters: {
        'employee_id': employeeId,
        'device_uuid': deviceUuid,
        if (deviceLabel != null) 'device_label': deviceLabel,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map ? e.response?.data['detail'] : null)
          ?? e.message
          ?? 'Network error';
      throw Exception(errorMsg);
    }
  }

  /// Fetch available punch types from server.
  Future<List<Map<String, dynamic>>> getPunchTypes() async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/punch-types');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw NetworkException('Network error');
      throw Exception('Failed to fetch punch types');
    }
  }

  bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.unknown;
}
