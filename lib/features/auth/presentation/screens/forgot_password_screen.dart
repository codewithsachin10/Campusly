import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(_emailController.text.trim());
      if (mounted && !ref.read(authControllerProvider).hasError) {
        setState(() {
          _emailSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          AppErrorHandler.showErrorSnackBar(context, error);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.0.w,
              vertical: 16.0.h,
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 480),
              padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 28.0.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1.w,
                ),
              ),
              child: _emailSent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Check your email',
                          style: AppTypography.textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "We've sent a password recovery link to ${_emailController.text.trim()}",
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Return to Log In',
                              style: AppTypography.textTheme.labelLarge
                                  ?.copyWith(color: AppColors.onPrimary),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Heading
                          Text(
                            'Reset your password',
                            style: AppTypography.textTheme.headlineLarge,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Enter the email address linked to your Campusly account and we'll send you a recovery link.",
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 32.h),
                          // Email Field
                          Text(
                            'EMAIL ADDRESS',
                            style: AppTypography.textTheme.labelLarge?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleReset(),
                            style: AppTypography.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Enter your account email',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32.h),
                          // Send Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleReset,
                              child: isLoading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Send Reset Link',
                                      style: AppTypography.textTheme.labelLarge
                                          ?.copyWith(
                                            color: AppColors.onPrimary,
                                            fontSize: 16.sp,
                                          ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
