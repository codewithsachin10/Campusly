import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusly/core/theme/app_spacing.dart';
import 'package:campusly/core/theme/app_radius.dart';
import 'package:campusly/core/theme/app_motion.dart';
import 'package:campusly/core/services/error_reporter.dart';

void main() {
  group('Theme Tokens & Constants', () {
    test('AppSpacing values are properly scaled and consistent', () {
      expect(AppSpacing.s4, 4.0);
      expect(AppSpacing.s8, 8.0);
      expect(AppSpacing.s12, 12.0);
      expect(AppSpacing.s16, 16.0);
      expect(AppSpacing.s20, 20.0);
      expect(AppSpacing.s24, 24.0);
      expect(AppSpacing.s32, 32.0);
      expect(AppSpacing.s40, 40.0);
      expect(AppSpacing.s48, 48.0);
      expect(AppSpacing.s64, 64.0);

      expect(AppSpacing.p16, const EdgeInsets.all(16.0));
      expect(AppSpacing.screenMargin, const EdgeInsets.symmetric(horizontal: 16.0));
    });

    test('AppRadius provides smooth rounded corner tokens', () {
      expect(AppRadius.k8, BorderRadius.circular(8.0));
      expect(AppRadius.k12, BorderRadius.circular(12.0));
      expect(AppRadius.k16, BorderRadius.circular(16.0));
      expect(AppRadius.k20, BorderRadius.circular(20.0));
      expect(AppRadius.k24, BorderRadius.circular(24.0));
      expect(AppRadius.pill, BorderRadius.circular(999.0));
    });

    test('AppMotion durations and curves adhere to 200-400ms range', () {
      expect(AppMotion.fast.inMilliseconds, inInclusiveRange(150, 250));
      expect(AppMotion.normal.inMilliseconds, inInclusiveRange(250, 350));
      expect(AppMotion.slow.inMilliseconds, inInclusiveRange(350, 450));
      expect(AppMotion.easeOut, Curves.easeOutCubic);
      expect(AppMotion.easeInOut, Curves.easeInOutCubic);
    });
  });

  group('ErrorReporter Service', () {
    setUp(() {
      ErrorReporter.clearHistory();
    });

    test('records errors with severity and maintains history', () {
      expect(ErrorReporter.recentErrors, isEmpty);

      final testError = StateError('Test state failure');
      final stack = StackTrace.current;

      ErrorReporter.recordError(
        testError,
        stack,
        reason: 'Custom test failure context',
        severity: ErrorSeverity.warning,
      );

      expect(ErrorReporter.recentErrors.length, 1);
      final report = ErrorReporter.recentErrors.first;
      expect(report.message, 'Custom test failure context');
      expect(report.exception, testError);
      expect(report.severity, ErrorSeverity.warning);
    });

    test('caps error history queue without unbounded growth', () {
      for (int i = 0; i < 40; i++) {
        ErrorReporter.recordError('Error #$i', null);
      }
      expect(ErrorReporter.recentErrors.length, 30);
      expect(ErrorReporter.recentErrors.last.message, 'Error #39');
    });
  });
}
