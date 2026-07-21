import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF3525CD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color onPrimaryContainer = Color(0xFFDAD7FF);
  static const Color primaryFixed = Color(0xFFE2DFFF);
  static const Color primaryFixedDim = Color(0xFFC3C0FF);
  static const Color onPrimaryFixed = Color(0xFF0F0069);
  static const Color onPrimaryFixedVariant = Color(0xFF3323CC);

  // Secondary
  static const Color secondary = Color(0xFF0058BE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF2170E4);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);
  static const Color secondaryFixed = Color(0xFFD8E2FF);
  static const Color secondaryFixedDim = Color(0xFFADC6FF);
  static const Color onSecondaryFixed = Color(0xFF001A42);
  static const Color onSecondaryFixedVariant = Color(0xFF004395);

  // Tertiary
  static const Color tertiary = Color(0xFF571AC0);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF6F3DD9);
  static const Color onTertiaryContainer = Color(0xFFE3D5FF);
  static const Color tertiaryFixed = Color(0xFFE9DDFF);
  static const Color tertiaryFixedDim = Color(0xFFD0BCFF);
  static const Color onTertiaryFixed = Color(0xFF23005C);
  static const Color onTertiaryFixedVariant = Color(0xFF5516BE);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surface & Background
  static const Color surface = Color(0xFFFAF9F8);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color surfaceVariant = Color(0xFFE3E2E1);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color surfaceBright = Color(0xFFFAF9F8);
  static const Color surfaceDim = Color(0xFFDADAD9);
  static const Color surfaceTint = Color(0xFF4D44E3);

  // Surface Containers
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F3F2);
  static const Color surfaceContainer = Color(0xFFEEEEED);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E7);
  static const Color surfaceContainerHighest = Color(0xFFE3E2E1);

  // Inverse
  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color inverseOnSurface = Color(0xFFF1F0F0);
  static const Color inversePrimary = Color(0xFFC3C0FF);

  // Outlines
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Background
  static const Color background = Color(0xFFFAF9F8);
  static const Color onBackground = Color(0xFF1A1C1C);

  // Helper and Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color border = Color(0xFFC7C4D8);
  static const Color textPrimary = Color(0xFF1A1C1C);
  static const Color textSecondary = Color(0xFF464555);
  static const Color divider = Color(0xFFC7C4D8);

  // Subject & Card Accent Colors (matching reference UI)
  static Color getSubjectAccentColor(String? subjectCode, {bool isBreak = false}) {
    if (isBreak) return const Color(0xFF8D6E63);
    if (subjectCode == null) return primary;
    switch (subjectCode.toUpperCase()) {
      case 'CS23333':
        return const Color(0xFF00E5FF); // Bright Cyan / Sky Blue
      case 'CB23333':
        return const Color(0xFFFFB300); // Vibrant Amber / Gold
      case 'CB23311':
        return const Color(0xFFFF9800); // Warm Orange
      case 'CB23332':
        return const Color(0xFFAB47BC); // Purple / Lavender
      case 'CB23331':
        return const Color(0xFFEF5350); // Rose / Red
      case 'MC23313':
        return const Color(0xFF26A69A); // Teal / Green
      case 'CB23312':
        return const Color(0xFF42A5F5); // Deep Blue / Indigo
      default:
        return primary;
    }
  }
}
