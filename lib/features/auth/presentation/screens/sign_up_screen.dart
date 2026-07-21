import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/campusly_logo.dart';
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
  final _customDeptController = TextEditingController();

  String? _selectedDepartment;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  final List<String> _departments = [
    'Computer Science & Engineering (CSE)',
    'Computer Science & Business Systems (CSBS)',
    'Information Technology (IT)',
    'Artificial Intelligence & Data Science (AI&DS)',
    'Electronics & Communication (ECE)',
    'Electrical & Electronics (EEE)',
    'Mechanical Engineering (MECH)',
    'Civil Engineering (CIVIL)',
    'Biotechnology (BIO)',
    'Management Studies (MBA/BBA)',
    'Other Department',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _customDeptController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms of Service & Privacy Policy.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      final departmentValue = _selectedDepartment == 'Other Department'
          ? _customDeptController.text.trim()
          : (_selectedDepartment ?? 'General');

      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            name: _nameController.text.trim(),
            department: departmentValue,
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo
                    const CampuslyLogo(size: 64, borderRadius: 16),
                    const SizedBox(height: 20),
                    // Heading Section
                    Text(
                      'Create your Campusly account',
                      style: AppTypography.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start organizing your college life in one place.',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Full Name Field
                    Text(
                      'FULL NAME',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 20),
                    // Department Field
                    Text(
                      'DEPARTMENT',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDepartment,
                      isExpanded: true,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'Select your department',
                        prefixIcon: Icon(
                          Icons.business_center_outlined,
                          size: 20,
                        ),
                      ),
                      items: _departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(
                            dept,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your department';
                        }
                        return null;
                      },
                    ),
                    if (_selectedDepartment == 'Other Department') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customDeptController,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Enter your department name',
                          prefixIcon: Icon(Icons.edit_outlined, size: 20),
                        ),
                        validator: (value) {
                          if (_selectedDepartment == 'Other Department' &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter your custom department';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Email Field
                    Text(
                      'EMAIL ID',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'student@college.edu',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email ID';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid college email ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password Field
                    Text(
                      'PASSWORD',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(
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
                    const SizedBox(height: 20),
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
                                  ?.copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Create Account Button
                    ThreeDPushableButton(
                      text: 'Create Account',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleSignUp,
                    ),
                    const SizedBox(height: 24),
                    // Footer Navigation
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                    fontSize: 16,
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
