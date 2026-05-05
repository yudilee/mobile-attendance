import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'api_service.dart';
import 'security_service.dart';

final Logger _logger = Logger();

/// Initializes local notification channels for Android.
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Handles FCM token registration and incoming push notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;

  /// Initialize FCM, request permissions, set up local notifications,
  /// and register token with the backend.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // ── Local notification channel setup (Android) ───────────────────
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(initSettings);

      // ── Request FCM permission (iOS 10+ / Android 13+) ───────────────
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // ── Get device UUID ──────────────────────────────────────────────
      String deviceUuid = 'unknown-device';
      try {
        final security = SecurityService();
        deviceUuid = await security.getDeviceUniqueId();
      } catch (e) {
        _logger.w('Could not get device UUID for FCM registration: $e');
      }

      // ── Get FCM token and register with backend ──────────────────────
      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        _logger.i('FCM token obtained: ${fcmToken.substring(0, 20)}...');
        await _registerToken(deviceUuid, fcmToken);
      }

      // ── Listen for token refresh ──────────────────────────────────────
      messaging.onTokenRefresh.listen((newToken) {
        _logger.i('FCM token refreshed');
        _registerToken(deviceUuid, newToken);
      });

      // ── Handle foreground messages ────────────────────────────────────
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // ── Handle notification tap (app opened from background) ──────────
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // ── Handle notification that opened app from terminated state ─────
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      _logger.i('NotificationService initialized successfully.');
    } catch (e) {
      _logger.e('Failed to initialize NotificationService: $e');
    }
  }

  /// Register/update the FCM token on the backend.
  Future<void> _registerToken(String deviceUuid, String token) async {
    try {
      final api = ApiService();
      await api.updateFcmToken(deviceUuid, token);
      _logger.i('FCM token registered with backend.');
    } catch (e) {
      _logger.e('Failed to register FCM token with backend: $e');
    }
  }

  /// Show a local notification when a push arrives while app is in foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      channelDescription: 'Notifications from the attendance system',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle when user taps a notification (navigate or log).
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    // Future: Navigate to specific screen based on data payload
    // final type = message.data['type'];
    // if (type == 'clock_in_reminder') { ... }
  }
}
