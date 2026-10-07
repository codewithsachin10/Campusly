import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ErrorSeverity { info, warning, error, fatal }

/// Structured record for caught errors and crashes
class AppErrorReport {
  final DateTime timestamp;
  final String message;
  final dynamic exception;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final String? contextInfo;

  AppErrorReport({
    required this.timestamp,
    required this.message,
    this.exception,
    this.stackTrace,
    this.severity = ErrorSeverity.error,
    this.contextInfo,
  });

  @override
  String toString() =>
      '[$severity] $timestamp: $message ${exception != null ? '($exception)' : ''}';
}

/// Centralized crash and error reporting service for Campusly.
class ErrorReporter {
  ErrorReporter._();

  static final Queue<AppErrorReport> _history = Queue<AppErrorReport>();
  static const int _maxHistory = 30;

  static List<AppErrorReport> get recentErrors => List.unmodifiable(_history);

  /// Record an error from any subsystem or async zone
  static void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    ErrorSeverity severity = ErrorSeverity.error,
    String? contextInfo,
  }) {
    final report = AppErrorReport(
      timestamp: DateTime.now(),
      message: reason ?? exception.toString(),
      exception: exception,
      stackTrace: stackTrace,
      severity: severity,
      contextInfo: contextInfo,
    );

    if (_history.length >= _maxHistory) {
      _history.removeFirst();
    }
    _history.add(report);

    if (kDebugMode) {
      debugPrint('[ErrorReporter] [${severity.name.toUpperCase()}] ${report.message}');
      if (exception != null && reason != null) {
        debugPrint('[ErrorReporter] Exception: $exception');
      }
      if (stackTrace != null) {
        debugPrint('[ErrorReporter] StackTrace:\n$stackTrace');
      }
    }
  }

  /// Hook for Flutter framework errors
  static void recordFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      reason: details.context?.toString() ?? 'Flutter framework error',
      severity: details.silent ? ErrorSeverity.warning : ErrorSeverity.error,
    );
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Clear in-memory history (useful for tests)
  static void clearHistory() {
    _history.clear();
  }
}

/// Riverpod ProviderObserver to capture state machine or async provider failures
base class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    ErrorReporter.recordError(
      error,
      stackTrace,
      reason: 'Provider ${context.provider.name ?? context.provider.runtimeType} failed',
      severity: ErrorSeverity.warning,
    );
  }
}
