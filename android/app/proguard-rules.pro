# Flutter standard ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Fix for Play Core / Deferred Components missing classes
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep models if they are used for JSON serialization (Dio/Schema)
-keep class com.example.mobile.models.** { *; }

# Google Fonts
-keep class com.google.fonts.** { *; }

# Shared Preferences
-keep class com.russhwolf.settings.** { *; }
