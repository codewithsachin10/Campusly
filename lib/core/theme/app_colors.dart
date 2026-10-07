import 'package:flutter/material.dart';
import 'subject_colors.dart';

class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo brand
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF4338CA);
  static const Color onPrimaryContainer = Color(0xFFEEF2FF);
  static const Color primaryFixed = Color(0xFFE0E7FF);
  static const Color primaryFixedDim = Color(0xFFC7D2FE);
  static const Color onPrimaryFixed = Color(0xFF1E1B4B);
  static const Color onPrimaryFixedVariant = Color(0xFF3730A3);

  // Warm Accent: Coral (#FF6B4A) for CTAs & "Now" states
  static const Color coral = Color(0xFFFF6B4A);
  static const Color onCoral = Color(0xFFFFFFFF);
  static const Color coralContainer = Color(0xFFFFE8E3);
  static const Color onCoralContainer = Color(0xFF6E1B08);

  // Mint Success (#10B981)
  static const Color mint = Color(0xFF10B981);
  static const Color onMint = Color(0xFFFFFFFF);
  static const Color mintContainer = Color(0xFFD1FAE5);
  static const Color onMintContainer = Color(0xFF064E3B);

  // Secondary maps to Coral accent
  static const Color secondary = coral;
  static const Color onSecondary = onCoral;
  static const Color secondaryContainer = coralContainer;
  static const Color onSecondaryContainer = onCoralContainer;
  static const Color secondaryFixed = Color(0xFFFFD4CB);
  static const Color secondaryFixedDim = Color(0xFFFFB4A4);
  static const Color onSecondaryFixed = Color(0xFF3E0A00);
  static const Color onSecondaryFixedVariant = Color(0xFF9C2910);

  // Tertiary maps to Mint success
  static const Color tertiary = mint;
  static const Color onTertiary = onMint;
  static const Color tertiaryContainer = mintContainer;
  static const Color onTertiaryContainer = onMintContainer;
  static const Color tertiaryFixed = Color(0xFFA7F3D0);
  static const Color tertiaryFixedDim = Color(0xFF6EE7B7);
  static const Color onTertiaryFixed = Color(0xFF022C22);
  static const Color onTertiaryFixedVariant = Color(0xFF047857);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // Surface & Background (Light)
  static const Color surface = Color(0xFFF8FAFC);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE2E8F0);
  static const Color surfaceTint = Color(0xFF4F46E5);

  // Surface Containers (Light)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);

  // Inverse (Light)
  static const Color inverseSurface = Color(0xFF0F172A);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);
  static const Color inversePrimary = Color(0xFFC7D2FE);

  // Outlines (Light)
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Background (Light)
  static const Color background = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF0F172A);

  // Dark Palette Tokens: Near-black (#0B0B14) with subtly tinted surfaces
  static const Color darkBackground = Color(0xFF0B0B14);
  static const Color darkSurface = Color(0xFF11111E);
  static const Color darkSurfaceContainerLowest = Color(0xFF07070D);
  static const Color darkSurfaceContainerLow = Color(0xFF141424);
  static const Color darkSurfaceContainer = Color(0xFF18182B);
  static const Color darkSurfaceContainerHigh = Color(0xFF1F1F36);
  static const Color darkSurfaceContainerHighest = Color(0xFF262642);
  static const Color darkOnSurface = Color(0xFFF1F1F8);
  static const Color darkOnSurfaceVariant = Color(0xFF9E9EB8);
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkPrimaryContainer = Color(0xFF4F46E5);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkSecondary = Color(0xFFFF6B4A); // Coral
  static const Color darkTertiary = Color(0xFF34D399); // Mint
  static const Color darkOutline = Color(0xFF2E2E48);
  static const Color darkOutlineVariant = Color(0xFF202034);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkSuccess = Color(0xFF34D399);

  // Semantic Colors
  static const Color success = mint;
  static const Color warning = Color(0xFFF59E0B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);

  // Subject & Card Accent Colors
  static Color getSubjectAccentColor(
    String? subjectCode, {
    bool isBreak = false,
  }) {
    if (isBreak) return const Color(0xFF8D6E63);
    return SubjectColors.forSubject(subjectCode);
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
  final Color coral;
  final Color mint;

  const AppCustomColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.subtleText,
    required this.success,
    required this.warning,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.chipBackground,
    required this.coral,
    required this.mint,
  });

  static const light = AppCustomColors(
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    subtleText: Color(0xFF64748B),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    shimmerBase: Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
    chipBackground: Color(0xFFF1F5F9),
    coral: Color(0xFFFF6B4A),
    mint: Color(0xFF10B981),
  );

  static const dark = AppCustomColors(
    cardBackground: Color(0xFF11111E),
    cardBorder: Color(0xFF202034),
    subtleText: Color(0xFF9E9EB8),
    success: Color(0xFF34D399),
    warning: Color(0xFFF59E0B),
    shimmerBase: Color(0xFF18182B),
    shimmerHighlight: Color(0xFF262642),
    chipBackground: Color(0xFF18182B),
    coral: Color(0xFFFF6B4A),
    mint: Color(0xFF34D399),
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
    Color? coral,
    Color? mint,
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
      coral: coral ?? this.coral,
      mint: mint ?? this.mint,
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
      coral: Color.lerp(coral, other.coral, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
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
