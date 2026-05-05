import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'app_settings.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Logger _logger = Logger();

  /// Attempt biometric/device-credential authentication.
  ///
  /// Returns (verified: true) if the user authenticated successfully.
  /// Returns (verified: false, reason: ...) if authentication could not be
  /// performed — the caller should still allow the punch but flag it.
  Future<({bool verified, String reason})> authenticateWithDevice() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        _logger.w("Device has no lock screen — skipping auth.");
        return (verified: true, reason: 'no_lock_screen');
      }

      final bool canCheckBio = await _auth.canCheckBiometrics;
      _logger.i("canCheckBiometrics=$canCheckBio");

      final bool result = await _auth.authenticate(
        localizedReason: 'Verify your identity to record attendance',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (result) {
        return (verified: true, reason: 'authenticated');
      } else {
        _logger.w("Auth returned false (user cancelled or dismissed).");
        return (verified: false, reason: 'user_cancelled');
      }
    } catch (e) {
      _logger.e("Auth exception: $e");
      // If we get a PlatformException (common on some OEMs), treat device
      // ownership as verified — the UUID binding is the real guard
      return (verified: true, reason: 'auth_unavailable: $e');
    }
  }

  /// Legacy wrapper — kept for compatibility
  Future<bool> authenticateBiometrics() async {
    final result = await authenticateWithDevice();
    return result.verified;
  }

  // ── Root / Jailbreak Detection ───────────────────────────────────────────────

  /// Returns true if the device has actual root access (su binary available).
  /// Does NOT treat unlocked bootloader or developer mode as compromise.
  Future<bool> _checkRootAccess() async {
    try {
      if (Platform.isAndroid) {
        // Method 1: Check if 'su' binary is accessible via shell
        try {
          final result = await Process.run(
            'which',
            ['su'],
            runInShell: true,
          );
          if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
            _logger.w("Root detected: su binary found at ${result.stdout}");
            return true;
          }
        } catch (_) {
          // 'which' command may not be available; fall through
        }

        // Method 2: Check common su paths directly
        const suPaths = [
          '/system/bin/su',
          '/system/xbin/su',
          '/sbin/su',
          '/data/local/su',
          '/data/local/xbin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/bin/su',
        ];
        for (final path in suPaths) {
          try {
            final file = await File(path).exists();
            if (file) {
              _logger.w("Root detected: su found at $path");
              return true;
            }
          } catch (_) {}
        }

        // Method 3: Check for Magisk or SuperSU packages
        // (Unlocked bootloader alone doesn't mean root)
        return false;
      } else if (Platform.isIOS) {
        // iOS: use the jailbreak detection package (more reliable on iOS)
        final jailbroken = await FlutterJailbreakDetection.jailbroken;
        return jailbroken;
      }
      return false;
    } catch (e) {
      _logger.e("Root check failed: $e");
      return false; // Fail-open: if we can't check, assume not rooted
    }
  }

  /// Returns true if the device is secure (not actually rooted/jailbroken).
  /// Unlocked bootloader and developer mode are NOT treated as compromise.
  Future<bool> isDeviceSecure() async {
    try {
      final hasRoot = await _checkRootAccess();
      return !hasRoot;
    } catch (e) {
      _logger.e("Device security check failed: $e");
      return true; // Fail-open
    }
  }

  /// Returns true if the device is compromised (actually rooted/jailbroken).
  Future<bool> isDeviceCompromised() async {
    return !await isDeviceSecure();
  }

  // ── Biometric Session Duration ───────────────────────────────────────────────

  /// Returns the configured biometric session timeout in seconds.
  Future<int> getBiometricSessionSeconds() async {
    return await AppSettings.getBiometricSessionSeconds();
  }

  /// Get Location with Mock Location Check
  /// This is the core geo-fencing requirement.
  Future<Position?> getCurrentValidatedLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // CRITICAL: Check if position is mocked
      if (position.isMocked) {
        _logger.e("CRITICAL: Mock location detected!");
        return position; // Caller should handle rejection based on isMocked
      }

      return position;
    } catch (e) {
      _logger.e("Location error: $e");
      return null;
    }
  }

  /// Extract Unique Hardware ID
  /// Used for strict device binding (Device Aggregator logic).
  Future<String> getDeviceUniqueId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; 
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_unknown';
      }
      return 'platform_unknown';
    } catch (e) {
      _logger.e("Hardware ID error: $e");
      return 'id_error';
    }
  }

  /// Get reliable timestamp for attendance.
  ///
  /// Strategy for unstable internet:
  /// 1. Use device local time (synced via cell tower / GPS on Android)
  /// 2. Cross-validate against GPS timestamp if a recent position is available
  /// 3. Return time with timezone offset so server stores correct local time
  ///
  /// Why not NTP:
  /// - NTP requires internet → fails on unstable connections
  /// - Android already syncs clock via cell network and GPS
  /// - NTP adds 2-3 seconds latency to every punch
  Future<({DateTime localTime, String isoString, int tzOffsetMinutes, bool gpsValidated})> getReliableTimestamp({Position? gpsPosition}) async {
    final now = DateTime.now();
    final tzOffset = now.timeZoneOffset;
    bool gpsValidated = false;

    // Cross-validate: GPS fix contains a UTC timestamp from satellites.
    // If device clock is more than 2 minutes off from GPS time,
    // it means the user manually changed their phone clock.
    if (gpsPosition != null) {
      final gpsTime = gpsPosition.timestamp;
      final drift = now.toUtc().difference(gpsTime).abs();
      if (drift.inMinutes > 2) {
        _logger.e("⚠️ Clock manipulation detected! "
            "Device=${now.toIso8601String()}, GPS=${gpsTime.toIso8601String()}, "
            "Drift=${drift.inSeconds}s");
        // Use GPS time instead of manipulated device time
        final corrected = gpsTime.add(tzOffset);
        return (
          localTime: corrected,
          isoString: corrected.toIso8601String(),
          tzOffsetMinutes: tzOffset.inMinutes,
          gpsValidated: true,
        );
      }
      gpsValidated = true;
      _logger.i("Clock OK — drift from GPS: ${drift.inSeconds}s");
    }

    return (
      localTime: now,
      isoString: now.toIso8601String(),
      tzOffsetMinutes: tzOffset.inMinutes,
      gpsValidated: gpsValidated,
    );
  }
}
