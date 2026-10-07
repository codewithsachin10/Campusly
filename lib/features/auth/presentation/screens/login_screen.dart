import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/widgets/campusly_logo.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/utils/error_handler.dart';
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
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authControllerProvider.notifier).signIn(
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Glow Backdrop (React / Aceternity style background mesh)
          Positioned(
            top: -100.h,
            left: -80.w,
            child: Container(
              width: 320.w,
              height: 320.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F46E5).withValues(alpha: 0.12),
                    const Color(0xFF4F46E5).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60.h,
            right: -60.w,
            child: Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.10),
                    const Color(0xFF38BDF8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 20.h),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 400.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pro React Card
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.0.w,
                            vertical: 28.0.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Status Pill (React Badge component)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: const Color(0xFFC7D2FE),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6.r,
                                          height: 6.r,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'STUDENT SECURE ACCESS',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5.sp,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                            color: const Color(0xFF4338CA),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 18.h),

                                // Logo & Title Row
                                Row(
                                  children: [
                                    CampuslyLogo(
                                      size: 40,
                                      borderRadius: 10,
                                      addShadow: false,
                                    ),
                                    SizedBox(width: 12.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Campusly',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.6,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Academic Management',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 22.h),

                                // Card Header
                                Text(
                                  'Sign in to account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Enter your student credentials to view your timetable & events.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5.sp,
                                    height: 1.4,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 22.h),

                                // Email Input Field (React-like Input)
                                _buildFieldLabel('Email address'),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: 'student@college.edu',
                                    prefixIcon: LucideIcons.mail,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16.h),

                                // Password Input Field
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildFieldLabel('Password'),
                                    InkWell(
                                      onTap: () => context.push('/forgot-password'),
                                      child: Text(
                                        'Forgot password?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: '••••••••••••',
                                    prefixIcon: LucideIcons.lock,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? LucideIcons.eye
                                            : LucideIcons.eyeOff,
                                        size: 16,
                                        color: const Color(0xFF94A3B8),
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
                                SizedBox(height: 14.h),

                                // Remember Me Option (React Checkbox)
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 20.r,
                                      width: 20.r,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberMe = val ?? true;
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                          width: 1.2,
                                        ),
                                        activeColor: const Color(0xFF4F46E5),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Remember this device',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),

                                // React Pro Button (Primary Sign In)
                                _buildPrimaryButton(isLoading),
                                SizedBox(height: 20.h),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: const Color(0xFFE2E8F0),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                                      child: Text(
                                        'or continue with',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: const Color(0xFFE2E8F0),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18.h),

                                // Google Auth Button (OAuth Component)
                                OutlinedButton(
                                  onPressed: isLoading ? null : _handleGoogleLogin,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 11.h),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GoogleLogo(size: 18),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 22.h),

                                // Create Account Row
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => context.push('/signup'),
                                      child: Text(
                                        'Create account',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Security Trust Badge beneath card
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.shieldCheck,
                              size: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '256-bit encrypted • Campusly Student Gateway',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
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
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      prefixIcon: Icon(
        prefixIcon,
        size: 16,
        color: const Color(0xFF94A3B8),
      ),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(
          color: Color(0xFF4F46E5),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isLoading) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF3730A3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: isLoading ? null : _handleLogin,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign in to Campusly',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
