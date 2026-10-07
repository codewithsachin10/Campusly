import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_motion.dart';

/// Single item entrance animation (fade-in + subtle vertical slide)
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double slideOffset;
  final Duration delay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.normal,
    this.slideOffset = 0.08,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) return child;

    // Cap index at 8 to prevent bottom-of-list items from taking too long to appear
    final cappedIndex = min(index, 8);
    final totalDelay = delay + (AppMotion.staggerStep * cappedIndex);

    return child
        .animate(delay: totalDelay)
        .fadeIn(
          duration: duration,
          curve: AppMotion.easeOut,
        )
        .slideY(
          begin: slideOffset,
          end: 0.0,
          duration: duration,
          curve: AppMotion.easeOut,
        );
  }
}

/// Helper extension on Widget to easily chain .staggerEntrance(index)
extension StaggerEntranceX on Widget {
  Widget staggerEntrance([int index = 0]) {
    return FadeSlideIn(index: index, child: this);
  }
}
