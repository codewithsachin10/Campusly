import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campusly_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final disableMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delayMs = disableMotion ? 200 : 2200;
    await Future.delayed(Duration(milliseconds: delayMs));

    if (!mounted) return;

    // Check auth state to navigate
    final authState = ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      context.go('/login');
    } else {
      if (!user.isProfileCompleted) {
        context.go('/complete-profile');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CampuslyLogo(
                          size: 64,
                          borderRadius: 16,
                          addShadow: true,
                        ),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
