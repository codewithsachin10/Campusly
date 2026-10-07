import 'package:flutter/material.dart';

/// Campusly Border Radius Design System Tokens
abstract final class AppRadius {
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;
  static const double full = 999.0;

  // Circular BorderRadius constants
  static const BorderRadius k4 = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius k8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius k12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius k16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius k20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius k24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius k32 = BorderRadius.all(Radius.circular(r32));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));

  // Vertical border radiuses (e.g. for bottom sheets, cards)
  static const BorderRadius top16 = BorderRadius.vertical(top: Radius.circular(r16));
  static const BorderRadius top20 = BorderRadius.vertical(top: Radius.circular(r20));
  static const BorderRadius top24 = BorderRadius.vertical(top: Radius.circular(r24));
  static const BorderRadius bottom16 = BorderRadius.vertical(bottom: Radius.circular(r16));
  static const BorderRadius bottom24 = BorderRadius.vertical(bottom: Radius.circular(r24));
}
