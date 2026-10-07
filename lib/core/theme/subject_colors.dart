import 'package:flutter/material.dart';

/// Deterministic HSL color generator for subjects, classes, categories, and tags.
/// Guarantees consistent, accessible visual identity across timetable rows,
/// attendance rings, notes, and event categories without hardcoded lookups.
abstract final class SubjectColors {
  /// Base saturation and lightness tuned for high contrast & harmony.
  static const double _lightSaturation = 0.68;
  static const double _lightLightness = 0.44;

  static const double _darkSaturation = 0.62;
  static const double _darkLightness = 0.58;

  /// Returns a deterministic, vibrant HSL color for any subject/class identifier.
  static Color forSubject(String? key, {bool isDark = false}) {
    if (key == null || key.trim().isEmpty) {
      return isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
    }

    final trimmed = key.trim();
    final lower = trimmed.toLowerCase();

    // Semantic overrides for common academic pauses/events
    if (lower.contains('break') || lower.contains('lunch') || lower.contains('recess')) {
      return isDark ? const Color(0xFF78716C) : const Color(0xFF8D6E63);
    }
    if (lower.contains('free') || lower.contains('library') || lower.contains('study')) {
      return isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    }
    if (lower.contains('lab') || lower.contains('practical')) {
      return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    }

    // FNV-1a 64-bit hash for uniform dispersion across 360-degree hue wheel
    var hash = 0xcbf29ce484222325;
    for (var i = 0; i < trimmed.length; i++) {
      hash ^= trimmed.codeUnitAt(i);
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }

    final hue = (hash.abs() % 360).toDouble();
    final saturation = isDark ? _darkSaturation : _lightSaturation;
    final lightness = isDark ? _darkLightness : _lightLightness;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// Returns a soft, readable container/pill background color for chips and cards.
  static Color containerForSubject(String? key, {bool isDark = false}) {
    final base = forSubject(key, isDark: isDark);
    final hsl = HSLColor.fromColor(base);
    if (isDark) {
      return hsl.withLightness(0.18).withSaturation(0.35).toColor();
    } else {
      return hsl.withLightness(0.93).withSaturation(0.40).toColor();
    }
  }

  /// Returns contrasting foreground text/icon color for `containerForSubject`.
  static Color onContainerForSubject(String? key, {bool isDark = false}) {
    final base = forSubject(key, isDark: isDark);
    final hsl = HSLColor.fromColor(base);
    if (isDark) {
      return hsl.withLightness(0.85).toColor();
    } else {
      return hsl.withLightness(0.28).toColor();
    }
  }

  /// Deterministic color for event categories (Technical, Cultural, Sports, Workshop, etc.)
  static Color forCategory(String? category, {bool isDark = false}) {
    return forSubject(category, isDark: isDark);
  }
}
