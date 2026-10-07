import 'package:flutter/material.dart';

/// Campusly Motion Design System Tokens
abstract final class AppMotion {
  // Standard Durations (200ms - 400ms)
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration modal = Duration(milliseconds: 350);
  static const Duration staggerStep = Duration(milliseconds: 50);

  // Standard Curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve emphasize = Curves.easeOutBack;

  /// Returns duration respecting user device accessibility reduce-motion settings
  static Duration durationOf(BuildContext context, [Duration duration = normal]) {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disable ? Duration.zero : duration;
  }
}
