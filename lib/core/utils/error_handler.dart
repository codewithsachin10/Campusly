import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static String getMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email address or password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Please choose a stronger password (at least 6 characters).';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many unsuccessful attempts. Please try again later or reset your password.';
        case 'network-request-failed':
          return 'Network connection error. Please check your internet connection and try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is currently disabled.';
        case 'requires-recent-login':
          return 'For security reasons, please log in again before performing this action.';
        default:
          return error.message ??
              'An authentication error occurred. Please try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access or modify this information.';
        case 'unavailable':
          return 'The service is temporarily unavailable. Please check your network or try again later.';
        case 'not-found':
          return 'The requested resource could not be found.';
        case 'already-exists':
          return 'This item already exists.';
        default:
          return error.message ?? 'A database error occurred (${error.code}).';
      }
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
    final message = getMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
