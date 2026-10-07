import 'package:flutter/services.dart';

/// Campusly Tactile Haptics Engine
abstract final class AppHaptics {
  /// Light impact for micro-interactions (chips, tab selection, card taps)
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact for positive confirmations, toggles, checkmarks
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for critical warnings or delete actions
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Subtle click for scroll pickers or list selection
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
