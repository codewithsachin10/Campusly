import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/campusly_logo.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../shared/widgets/three_d_pushable_button.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (mounted && !ref.read(authControllerProvider).hasError) {
      // The router should automatically handle the redirect based on auth state and is_profile_completed
    }
  }

  Future<void> _handleSignUp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the Terms of Service & Privacy Policy.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rollNumber: _rollNumberController.text.trim(),
          );
      if (mounted && !ref.read(authControllerProvider).hasError) {
        context.go('/verify-email', extra: _emailController.text.trim());
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo
                    CampuslyLogo(size: 64, borderRadius: 16),
                    SizedBox(height: 20.h),
                    // Heading Section
                    Text(
                      'Create your Campusly account',
                      style: AppTypography.textTheme.headlineLarge,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Start organizing your college life in one place.',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    
                    // Primary Google Sign In Button
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: double.infinity, minHeight: 54),
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        icon: GoogleLogo(size: 24),
                        label: Text(
                          'Continue with Google',
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            fontSize: 16.sp,
                            color: AppColors.onSurface,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: AppColors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.outlineVariant)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'OR',
                            style: AppTypography.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.outlineVariant)),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Full Name Field
                    Text(
                      'FULL NAME',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    
                    // Roll Number Field
                    Text(
                      'ROLL NUMBER',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _rollNumberController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'e.g. 211520104001',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your roll number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Email Field
                    Text(
                      'COLLEGE EMAIL ID',
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
                        hintText: 'student@rajalakshmi.edu.in',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email ID';
                        }
                        if (!value.contains('@rajalakshmi.edu.in')) {
                          return 'Please enter a valid college email ID';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    // Password Field
                    Text(
                      'PASSWORD',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
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
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    // Terms Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _agreedToTerms = !_agreedToTerms,
                            ),
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: AppTypography.textTheme.bodySmall
                                  ?.copyWith(fontSize: 13.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    // Create Account Button
                    ThreeDPushableButton(
                      text: 'Create Account',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleSignUp,
                    ),
                    SizedBox(height: 24.h),
                    // Footer Navigation
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.pop(),
                            child: Text(
                              'Log In',
                              style: AppTypography.textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 16.sp,
                                  ),
                            ),
                          ),
                        ],
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
