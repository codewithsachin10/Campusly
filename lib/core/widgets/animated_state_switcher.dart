import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Smooth AnimatedSwitcher for transitioning between Loading, Error, and Content states
class AnimatedStateSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedStateSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.curve = AppMotion.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return child;
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
