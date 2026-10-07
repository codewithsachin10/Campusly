import 'package:flutter/widgets.dart';

/// App shadow design tokens.
class AppShadows {
  AppShadows._();

  /// Primary subtle shadow token (blur 12, alpha .06, offset 0,4)
  static const BoxShadow card = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.06),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const List<BoxShadow> cardShadow = [card];
}
