import 'package:flutter/material.dart';

/// Campusly Spacing Design System Tokens
abstract final class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // Inset padding
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p20 = EdgeInsets.all(s20);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  // Horizontal padding
  static const EdgeInsets ph8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets ph12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets ph16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets ph20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets ph24 = EdgeInsets.symmetric(horizontal: s24);
  static const EdgeInsets ph32 = EdgeInsets.symmetric(horizontal: s32);

  // Vertical padding
  static const EdgeInsets pv4 = EdgeInsets.symmetric(vertical: s4);
  static const EdgeInsets pv8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets pv12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets pv16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets pv20 = EdgeInsets.symmetric(vertical: s20);
  static const EdgeInsets pv24 = EdgeInsets.symmetric(vertical: s24);
  static const EdgeInsets pv32 = EdgeInsets.symmetric(vertical: s32);

  // Screen horizontal margins
  static const EdgeInsets screenMargin = EdgeInsets.symmetric(horizontal: s16);

  // Vertical gap helpers
  static const Widget v4 = SizedBox(height: s4);
  static const Widget v8 = SizedBox(height: s8);
  static const Widget v12 = SizedBox(height: s12);
  static const Widget v16 = SizedBox(height: s16);
  static const Widget v20 = SizedBox(height: s20);
  static const Widget v24 = SizedBox(height: s24);
  static const Widget v32 = SizedBox(height: s32);
  static const Widget v40 = SizedBox(height: s40);
  static const Widget v48 = SizedBox(height: s48);
  static const Widget v64 = SizedBox(height: s64);

  // Horizontal gap helpers
  static const Widget h4 = SizedBox(width: s4);
  static const Widget h8 = SizedBox(width: s8);
  static const Widget h12 = SizedBox(width: s12);
  static const Widget h16 = SizedBox(width: s16);
  static const Widget h20 = SizedBox(width: s20);
  static const Widget h24 = SizedBox(width: s24);
  static const Widget h32 = SizedBox(width: s32);
}
