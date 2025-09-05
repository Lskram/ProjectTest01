import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color constants
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryRed = Color(0xFFF44336);

  // Light theme colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = primaryBlue;
  static const Color lightSecondary = primaryOrange;
  static const Color lightError = primaryRed;

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFFFFB74D);
  static const Color darkError = Color(0xFFEF5350);

  /// Get light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        background: lightBackground,
        error: lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        onBackground: Color(0xFF1A1A1A),
        onError: Colors.white,
        outline: Color(0xFFE0E0E0),
        surfaceVariant: Color(0xFFF5F5F5),
        onSurfaceVariant: Color(0xFF757575),
      ),

      // Typography
      textTheme: _buildTextTheme(Brightness.light),

      // App bar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: lightSurface,
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightPrimary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightError),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightPrimary;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightPrimary.withOpacity(0.3);
          }
          return Colors.grey.shade300;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightPrimary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: Color(0xFFBDBDBD), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab bar
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightPrimary,
        circularTrackColor: Color(0xFFE0E0E0),
        linearTrackColor: Color(0xFFE0E0E0),
      ),
    );
  }

  /// Get dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        background: darkBackground,
        error: darkError,
        onPrimary: Color(0xFF1A1A1A),
        onSecondary: Color(0xFF1A1A1A),
        onSurface: Color(0xFFE0E0E0),
        onBackground: Color(0xFFE0E0E0),
        onError: Color(0xFF1A1A1A),
        outline: Color(0xFF404040),
        surfaceVariant: Color(0xFF2A2A2A),
        onSurfaceVariant: Color(0xFFB0B0B0),
      ),

      // Typography
      textTheme: _buildTextTheme(Brightness.dark),

      // App bar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: Color(0xFFE0E0E0),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkSurface,
        shadowColor: Colors.black.withOpacity(0.3),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF1A1A1A),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkError),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimary;
          }
          return Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimary.withOpacity(0.3);
          }
          return Colors.grey.shade700;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: Color(0xFF757575), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textColor: Color(0xFFE0E0E0),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab bar
      tabBarTheme: const TabBarTheme(
        labelColor: Color(0xFFE0E0E0),
        unselectedLabelColor: Color(0xFF757575),
        indicatorColor: darkPrimary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      // Snackbar
      snackBarThemeData: SnackBarThemeData(
        backgroundColor: const Color(0xFF424242),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
        circularTrackColor: Color(0xFF404040),
        linearTrackColor: Color(0xFF404040),
      ),
    );
  }

  /// Build text theme for specific brightness
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE0E0E0);

    final mutedColor = brightness == Brightness.light
        ? const Color(0xFF757575)
        : const Color(0xFFB0B0B0);

    return GoogleFonts.notoSansThaiTextTheme().copyWith(
      // Display styles
      displayLarge: GoogleFonts.notoSansThai(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.notoSansThai(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.notoSansThai(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.3,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.notoSansThai(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.notoSansThai(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.notoSansThai(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),

      // Title styles
      titleLarge: GoogleFonts.notoSansThai(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.notoSansThai(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.notoSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),

      // Body styles
      bodyLarge: GoogleFonts.notoSansThai(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.notoSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.notoSansThai(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.5,
      ),

      // Label styles
      labelLarge: GoogleFonts.notoSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.notoSansThai(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.notoSansThai(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        height: 1.4,
      ),
    );
  }

  /// Get theme color by name
  static Color getThemeColor(String colorName, {bool isDark = false}) {
    switch (colorName.toLowerCase()) {
      case 'primary':
        return isDark ? darkPrimary : lightPrimary;
      case 'secondary':
        return isDark ? darkSecondary : lightSecondary;
      case 'background':
        return isDark ? darkBackground : lightBackground;
      case 'surface':
        return isDark ? darkSurface : lightSurface;
      case 'error':
        return isDark ? darkError : lightError;
      case 'success':
        return primaryGreen;
      case 'warning':
        return primaryOrange;
      case 'info':
        return primaryBlue;
      default:
        return isDark ? darkPrimary : lightPrimary;
    }
  }

  /// Get gradient colors
  static List<Color> getGradientColors(String gradientName,
      {bool isDark = false}) {
    switch (gradientName.toLowerCase()) {
      case 'primary':
        return isDark
            ? [darkPrimary, darkPrimary.withOpacity(0.7)]
            : [lightPrimary, lightPrimary.withOpacity(0.7)];
      case 'success':
        return [primaryGreen, primaryGreen.withOpacity(0.7)];
      case 'warning':
        return [primaryOrange, primaryOrange.withOpacity(0.7)];
      case 'error':
        return isDark
            ? [darkError, darkError.withOpacity(0.7)]
            : [lightError, lightError.withOpacity(0.7)];
      case 'sunset':
        return [primaryOrange, primaryRed];
      case 'ocean':
        return [primaryBlue, primaryPurple];
      case 'forest':
        return [primaryGreen, primaryBlue];
      default:
        return isDark
            ? [darkPrimary, darkSecondary]
            : [lightPrimary, lightSecondary];
    }
  }

  /// Get shadow color based on theme
  static Color getShadowColor(bool isDark) {
    return isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
  }

  /// Get surface tint color
  static Color getSurfaceTint(bool isDark) {
    return isDark
        ? darkPrimary.withOpacity(0.05)
        : lightPrimary.withOpacity(0.05);
  }

  /// Check if color is dark
  static bool isColorDark(Color color) {
    final luminance = color.computeLuminance();
    return luminance < 0.5;
  }

  /// Get contrasting text color
  static Color getContrastingTextColor(Color backgroundColor) {
    return isColorDark(backgroundColor) ? Colors.white : Colors.black;
  }

  /// Create custom color scheme
  static ColorScheme createCustomColorScheme({
    required Color primary,
    required bool isDark,
  }) {
    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        secondary: primary.withOpacity(0.7),
        surface: darkSurface,
        background: darkBackground,
        error: darkError,
      );
    } else {
      return ColorScheme.light(
        primary: primary,
        secondary: primary.withOpacity(0.7),
        surface: lightSurface,
        background: lightBackground,
        error: lightError,
      );
    }
  }
}
