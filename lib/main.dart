import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'ui/theme.dart';
import 'ui/screens/home_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _isLoading = true;
  bool _needsUpdate = false;
  String _updateMessage = "";

  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    try {
      final api = ApiService();
      final status = await api.checkAppStatus();
      if (status['status'] == 'ok') {
        final minVersion = status['min_version'] as String;
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        // Simple version check (assuming semantic versioning like 1.0.0)
        if (_isVersionOlder(currentVersion, minVersion)) {
          setState(() {
            _needsUpdate = true;
            _updateMessage = status['message'] ?? 'Update Required. Please contact IT for the latest APK.';
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('App version check failed: $e');
    }
    setState(() => _isLoading = false);
  }

  bool _isVersionOlder(String current, String minVer) {
    try {
      List<int> curParts = current.split('.').map(int.parse).toList();
      List<int> minParts = minVer.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        int c = i < curParts.length ? curParts[i] : 0;
        int m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (_isLoading) {
      homeWidget = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_needsUpdate) {
      homeWidget = Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Update Required', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Text(_updateMessage, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    } else {
      homeWidget = const HomeScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virtual Attendance',
      theme: AppTheme.lightTheme,
      home: homeWidget,
    );
  }
}

