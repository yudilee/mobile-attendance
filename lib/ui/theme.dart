import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cyber-Tech Colors
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color secondaryViolet = Color(0xFF8B5CF6);
  static const Color backgroundDeep = Color(0xFF0F172A);
  static const Color surfaceGlass = Color(0x331E293B); // 20% opacity for glass effect
  static const Color surfaceGlassBorder = Color(0x33FFFFFF);
  
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // Success / Error / Warning
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF59E0B);

  // Gradient for prominent buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, secondaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Common Glassmorphism Decoration
  static BoxDecoration glassDecoration({BuildContext? context, double borderRadius = 20, bool withBorder = true}) {
    final isDark = context == null || Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? surfaceGlass : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder 
          ? Border.all(color: isDark ? surfaceGlassBorder : Colors.grey.withOpacity(0.1), width: 1.0) 
          : null,
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
          blurRadius: 16,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Light theme (beautiful frosted light mode)
  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light, isDark: false);
  }

  // Primary Dark Theme (Stitch Redesign)
  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark, isDark: true);
  }

  static ThemeData _buildTheme(Brightness brightness, {required bool isDark}) {
    final Color bgColor = isDark ? backgroundDeep : const Color(0xFFF8FAFC);
    final Color surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? textMain : const Color(0xFF1E293B);
    final Color textSecColor = isDark ? textMuted : const Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: primaryCyan,
        primary: primaryCyan,
        secondary: secondaryViolet,
        surface: bgColor,
        onSurface: textColor,
        onSurfaceVariant: textSecColor,
        error: errorRed,
      ),
      scaffoldBackgroundColor: bgColor,
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFFFFFFF),
        selectedItemColor: primaryCyan,
        unselectedItemColor: textSecColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSecColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryCyan;
          return surfaceColor;
        }),
      ),
    );
  }
}
