import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Standard motion parameters compliant with Campusly Design System
abstract final class AppTransitions {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration modalDuration = Duration(milliseconds: 350);
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve reverseCurve = Curves.easeInCubic;

  /// Fade-through transition (e.g. for top-level destinations and splash/auth transitions)
  static CustomTransitionPage<T> fadeThrough<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations ? Duration.zero : defaultDuration;

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (disableAnimations) return child;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
          reverseCurve: reverseCurve,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
    );
  }

  /// Slide + Fade transition (Shared-axis push transition for drill-down screens)
  static CustomTransitionPage<T> slideFade<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations ? Duration.zero : defaultDuration;

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (disableAnimations) return child;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
          reverseCurve: reverseCurve,
        );

        final slideTween = Tween<Offset>(
          begin: const Offset(0.08, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideTween,
          child: FadeTransition(
            opacity: fadeTween,
            child: child,
          ),
        );
      },
    );
  }

  /// Slide-up modal transition (for sheets, creation dialogs, alerts, forms)
  static CustomTransitionPage<T> slideUp<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations ? Duration.zero : modalDuration;

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (disableAnimations) return child;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
          reverseCurve: reverseCurve,
        );

        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 0.12),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideTween,
          child: FadeTransition(
            opacity: fadeTween,
            child: child,
          ),
        );
      },
    );
  }
}
