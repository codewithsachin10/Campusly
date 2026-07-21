import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // display-lg (48px, 800, -0.04em)
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.04 * 48,
        color: AppColors.onSurface,
      ),
      // headline-lg (32px, 700, -0.02em)
      headlineLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.02 * 32,
        color: AppColors.onSurface,
      ),
      // headline-lg-mobile (28px, 700)
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onSurface,
      ),
      // headline-md (24px, 600)
      headlineSmall: GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.onSurface,
      ),
      // headline-sm (20px, 600)
      titleLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onSurface,
      ),
      // body-lg (18px, 400)
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.onSurface,
      ),
      // body-md (16px, 400)
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      ),
      // body-sm / caption (14px, 400)
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.onSurfaceVariant,
      ),
      // label-md (14px, 600, uppercase 0.05em)
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.05 * 14,
        color: AppColors.onSurface,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.05 * 12,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  static TextStyle get displayLarge => textTheme.displayLarge!;
  static TextStyle get headlineLarge => textTheme.headlineLarge!;
  static TextStyle get headlineMedium => textTheme.headlineMedium!;
  static TextStyle get headlineSmall => textTheme.headlineSmall!;
  static TextStyle get titleLarge => textTheme.titleLarge!;
  static TextStyle get titleMedium => textTheme.headlineSmall!; // fallback or mapping
  static TextStyle get titleSmall => textTheme.labelLarge!; // fallback or mapping
  static TextStyle get bodyLarge => textTheme.bodyLarge!;
  static TextStyle get bodyMedium => textTheme.bodyMedium!;
  static TextStyle get bodySmall => textTheme.bodySmall!;
  static TextStyle get labelLarge => textTheme.labelLarge!;
  static TextStyle get labelMedium => textTheme.labelMedium!;
  static TextStyle get labelSmall => textTheme.labelMedium!; // fallback or mapping
}
