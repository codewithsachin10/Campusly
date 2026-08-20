import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/campusly_logo.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../shared/widgets/three_d_pushable_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  Future<void> _handleGoogleLogin() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0.w),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 480),
              padding: EdgeInsets.all(32.0.w),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CampuslyLogo(size: 80, borderRadius: 20),
                          SizedBox(width: 16.w),
                          Text(
                            'Campusly',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 42.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Header Title & Subtitle
                    Text(
                      'Welcome back 👋',
                      style: AppTypography.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Let's get your day organized.",
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMAIL',
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
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
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'PASSWORD',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      letterSpacing: 1.2,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () => context.push('/forgot-password'),
                              child: Text(
                                'Forgot password?',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: AppTypography.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    // Log In Button
                    ThreeDPushableButton(
                      text: 'Log In',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleLogin,
                    ),
                    SizedBox(height: 24.h),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppColors.outlineVariant),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: AppTypography.textTheme.labelMedium
                                ?.copyWith(fontSize: 11.sp, letterSpacing: 1.0),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppColors.outlineVariant),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Social Google Auth Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _handleGoogleLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GoogleLogo(size: 22),
                            SizedBox(width: 10.w),
                            Flexible(
                              child: Text(
                                'Continue with Google',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(fontSize: 15.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    // Footer Sign Up Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Create account',
                            style: AppTypography.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ],
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
