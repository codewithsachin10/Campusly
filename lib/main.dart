import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/push_notification_service.dart';

import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Global FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error: $error\n$stack');
    return true; // Prevent default crash behavior
  };

  try {
    await Supabase.initialize(
      url: 'https://jvrxoyswzjuhsofqnqym.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('Push Notification initialization failed: $e');
  }

  runApp(ProviderScope(child: CampuslyApp()));
}

class CampuslyApp extends ConsumerWidget {
  const CampuslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Campusly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16.h),
                    Text(
                      'Something went wrong.',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'We apologize for the inconvenience. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child!;
      },
    );
  }
}
