import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashReporting {
  static Future<void> initialize() async {
    if (kIsWeb) return; // Crashlytics is not supported on web

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  static Future<void> log(String message) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.log(message);
  }

  static Future<void> setUserId(String identifier) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }
}
