import 'package:flutter/material.dart';

class AppColors {
  // Light Palette
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

  // Surface & Background (Light)
  static const Color surface = Color(0xFFFAF9F8);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color surfaceVariant = Color(0xFFE3E2E1);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color surfaceBright = Color(0xFFFAF9F8);
  static const Color surfaceDim = Color(0xFFDADAD9);
  static const Color surfaceTint = Color(0xFF4D44E3);

  // Surface Containers (Light)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F3F2);
  static const Color surfaceContainer = Color(0xFFEEEEED);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E7);
  static const Color surfaceContainerHighest = Color(0xFFE3E2E1);

  // Inverse (Light)
  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color inverseOnSurface = Color(0xFFF1F0F0);
  static const Color inversePrimary = Color(0xFFC3C0FF);

  // Outlines (Light)
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Background (Light)
  static const Color background = Color(0xFFFAF9F8);
  static const Color onBackground = Color(0xFF1A1C1C);

  // Dark Palette Tokens
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF151821);
  static const Color darkSurfaceContainerLow = Color(0xFF1B1E29);
  static const Color darkSurfaceContainer = Color(0xFF222634);
  static const Color darkSurfaceContainerHigh = Color(0xFF2B3041);
  static const Color darkSurfaceContainerHighest = Color(0xFF343A4E);
  static const Color darkOnSurface = Color(0xFFE5E7EB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkPrimaryContainer = Color(0xFF4F46E5);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkSecondary = Color(0xFF60A5FA);
  static const Color darkOutline = Color(0xFF4B5563);
  static const Color darkOutlineVariant = Color(0xFF374151);
  static const Color darkError = Color(0xFFF87171);

  // Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1A1C1C);
  static const Color textSecondary = Color(0xFF464555);
  static const Color divider = Color(0xFFE2E8F0);

  // Subject & Card Accent Colors
  static Color getSubjectAccentColor(
    String? subjectCode, {
    bool isBreak = false,
  }) {
    if (isBreak) return const Color(0xFF8D6E63);
    if (subjectCode == null) return primary;

    if (subjectCode.startsWith('#')) {
      try {
        final hex = subjectCode.replaceFirst('#', '0xFF');
        return Color(int.parse(hex));
      } catch (_) {
        return primary;
      }
    }

    switch (subjectCode.toUpperCase()) {
      case 'CS23333':
        return const Color(0xFF0284C7); // Sky Blue
      case 'CB23333':
        return const Color(0xFFD97706); // Amber / Gold
      case 'CB23311':
        return const Color(0xFFEA580C); // Warm Orange
      case 'CB23332':
        return const Color(0xFF9333EA); // Purple
      case 'CB23331':
        return const Color(0xFFE11D48); // Rose
      case 'MC23313':
        return const Color(0xFF0D9488); // Teal
      case 'CB23312':
        return const Color(0xFF2563EB); // Royal Blue
      default:
        return primary;
    }
  }
}

/// Custom Semantic Colors Extension for Complete Light/Dark Mode Fidelity
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color cardBackground;
  final Color cardBorder;
  final Color subtleText;
  final Color success;
  final Color warning;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color chipBackground;

  const AppCustomColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.subtleText,
    required this.success,
    required this.warning,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.chipBackground,
  });

  static const light = AppCustomColors(
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    subtleText: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    shimmerBase: Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
    chipBackground: Color(0xFFF1F5F9),
  );

  static const dark = AppCustomColors(
    cardBackground: Color(0xFF181B24),
    cardBorder: Color(0xFF282D3B),
    subtleText: Color(0xFF9CA3AF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    shimmerBase: Color(0xFF1F2432),
    shimmerHighlight: Color(0xFF2C3345),
    chipBackground: Color(0xFF222634),
  );

  @override
  AppCustomColors copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? subtleText,
    Color? success,
    Color? warning,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? chipBackground,
  }) {
    return AppCustomColors(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      subtleText: subtleText ?? this.subtleText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      chipBackground: chipBackground ?? this.chipBackground,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
    );
  }
}

/// Convenient Theme extension on BuildContext
extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  AppCustomColors get customColors =>
      Theme.of(this).extension<AppCustomColors>() ?? AppCustomColors.light;
}
