import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration using Material 3 with OLED-optimized dark mode.
///
/// Colors follow the mobile-color-system skill guidelines:
/// - Dark mode background: true black (#000000) for OLED battery savings
/// - Text: #E8E8E8 (not pure white, easier on eyes)
/// - Desaturated primary colors in dark mode
class AppTheme {
  static const _seedColor = Color(0xFF0369A1); // Deep sky blue

  /// Light theme.
  static ThemeData lightTheme(ColorScheme? dynamicScheme) {
    final colorScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAFA),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dark theme – OLED-optimized with true black background.
  static ThemeData darkTheme(ColorScheme? dynamicScheme) {
    final baseScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        );

    final colorScheme = baseScheme.copyWith(
      surface: const Color(0xFF1E1E1E), // Slightly lighter surface for cards
      // OLED-optimized overrides or desaturated colors if not using dynamic
      primary: dynamicScheme != null ? null : const Color(0xFF7DD3FC),
      secondary: dynamicScheme != null ? null : const Color(0xFF86EFAC),
      error: const Color(0xFFF2B8B5),
      onSurface: const Color(0xFFE8E8E8), // Not pure white
    );


    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.black, // True black for OLED
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E1E1E),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build text theme using Outfit for headlines, Inter for body.
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final headlineStyle = GoogleFonts.outfit(color: colorScheme.onSurface);
    final bodyStyle = GoogleFonts.inter(color: colorScheme.onSurface);

    return TextTheme(
      displayLarge: headlineStyle.copyWith(fontSize: 57),
      displayMedium: headlineStyle.copyWith(fontSize: 45),
      displaySmall: headlineStyle.copyWith(fontSize: 36),
      headlineLarge: headlineStyle.copyWith(fontSize: 32),
      headlineMedium: headlineStyle.copyWith(fontSize: 28),
      headlineSmall: headlineStyle.copyWith(fontSize: 24),
      titleLarge: headlineStyle.copyWith(fontSize: 22),
      titleMedium: bodyStyle.copyWith(
          fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: bodyStyle.copyWith(
          fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: bodyStyle.copyWith(fontSize: 16),
      bodyMedium: bodyStyle.copyWith(fontSize: 14),
      bodySmall: bodyStyle.copyWith(fontSize: 12),
      labelLarge: bodyStyle.copyWith(
          fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: bodyStyle.copyWith(
          fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: bodyStyle.copyWith(
          fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
