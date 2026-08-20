import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static String getErrorMessage(Object? error) {
    if (error == null) return 'An unknown error occurred.';
    if (error is AuthException) {
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is PlatformException) {
      return error.message ?? 'A platform error occurred. Please try again.';
    }

    final errStr = error.toString();
    if (errStr.contains('SocketException') ||
        errStr.contains('Network connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Clean up generic exception prefixes
    return errStr
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .trim();
  }

  static void showErrorSnackBar(BuildContext context, Object error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
