import 'package:flutter/material.dart';

/// Utility class for color constants and theme-related helpers
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Priority colors
  static const Color priorityHigh = Color(0xFFEF5350); // Red
  static const Color priorityMedium = Color(0xFFFFA726); // Orange
  static const Color priorityLow = Color(0xFF66BB6A); // Green

  // Status colors
  static const Color completed = Color(0xFF4CAF50); // Green
  static const Color pending = Color(0xFF9E9E9E); // Grey

  // Neutral colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFDEDEDE);
  static const Color text = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);

  // Get priority color based on priority level
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return Colors.grey;
    }
  }
}

/// Utility class for animation durations
class AppAnimations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration extraLong = Duration(milliseconds: 800);
}

/// Utility class for spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Utility class for border radius
class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;
}

/// Utility class for shadows
class AppShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow small = BoxShadow(
    color: Color(0x24000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x3D000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x3D000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}
