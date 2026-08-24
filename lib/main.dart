import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ui/theme.dart';
import 'ui/screens/home_screen.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'services/crash_reporting.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for FCM push notifications)
  try {
    await Firebase.initializeApp();
    await CrashReporting.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed (non-fatal): $e');
    // App continues without push notifications
  }

  // Initialize notification service (FCM token registration, handlers)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service init failed (non-fatal): $e');
  }

  runApp(
    const ProviderScope(
      child: AttendanceApp(),
    ),
  );
}

class AttendanceApp extends ConsumerStatefulWidget {
  const AttendanceApp({super.key});

  @override
  ConsumerState<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends ConsumerState<AttendanceApp> {
  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virtual Attendance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      home: const HomeScreen(),
    );
  }
}

