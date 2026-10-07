import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/error_reporter.dart';
import 'core/widgets/connectivity_banner.dart';
import 'core/widgets/error_state.dart';

import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handling
  FlutterError.onError = ErrorReporter.recordFlutterError;

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return Scaffold(
      body: SafeArea(
        child: ErrorState(
          title: 'Something went wrong',
          message: kReleaseMode
              ? 'An unexpected error occurred. Please try again.'
              : errorDetails.exceptionAsString(),
        ),
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.recordError(
      error,
      stack,
      reason: 'Global unhandled async exception',
      severity: ErrorSeverity.fatal,
    );
    return true; // Prevent default crash behavior
  };

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  } else {
    debugPrint(
      'WARNING: SUPABASE_URL and SUPABASE_ANON_KEY must be passed via --dart-define:\n'
      'flutter run --dart-define=SUPABASE_URL=<URL> --dart-define=SUPABASE_ANON_KEY=<KEY>',
    );
  }

  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('Push Notification initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      observers: [AppProviderObserver()],
      child: CampuslyApp(),
    ),
  );
}

class CampuslyApp extends ConsumerWidget {
  const CampuslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Campusly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          builder: (context, routerChild) {
            return ConnectivityBanner(
              child: routerChild ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
