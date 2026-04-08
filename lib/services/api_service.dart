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
  Dio? _dio;
  final Logger _logger = Logger();

  /// Returns a configured Dio instance with the current server URL and API key.
  /// Lazily initialized and recreated if settings change.
  Future<Dio> _getDio() async {
    final serverUrl = await AppSettings.getServerUrl();
    final apiKey = await AppSettings.getApiKey();

    _dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    return _dio!;
  }

  /// Submit the Attendance Punch to the FastAPI Middleware
  Future<Map<String, dynamic>> submitPunch({
    required String employeeId,
    required String deviceUuid,
    required double lat,
    required double lon,
    required bool isMocked,
    required bool biometricVerified,
    required String punchType,
    required String timestamp,
    int tzOffsetMinutes = 420, // Default: GMT+7 (420 minutes)
    bool gpsValidated = false,
  }) async {
    final dio = await _getDio();
    try {
      _logger.i('Attempting punch: $punchType for $employeeId');

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
      });

      _logger.i('Punch successful: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Network error';
      _logger.e('Punch failed: $errorMsg', error: e);
      
      // Distinguish network/connection errors from other HTTP errors (e.g. 400 Bad Request)
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.sendTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw NetworkException(errorMsg);
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      _logger.e('Unexpected error', error: e);
      throw Exception('An unexpected error occurred during punch.');
    }
  }

  /// Fetch the branch assignment and geofence data for this device
  Future<Map<String, dynamic>> getDeviceConfig({
    required String employeeId,
    required String deviceUuid,
  }) async {
    final dio = await _getDio();
    try {
      final response = await dio.get('/api/v1/device-config', queryParameters: {
        'employee_id': employeeId,
        'device_uuid': deviceUuid,
      });
      return response.data;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Network error';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to fetch device config');
    }
  }
}
