import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/class_join/presentation/providers/class_provider.dart';
import '../../features/class_join/presentation/screens/create_class_screen.dart';
import '../../features/class_join/presentation/screens/join_by_code_screen.dart';
import '../../features/class_join/presentation/screens/join_or_search_class_screen.dart';
import '../../features/class_join/presentation/screens/search_class_screen.dart';
import '../../features/timetable/presentation/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final currentClass = ref.watch(currentClassProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String?;
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/join-class-choice',
        builder: (context, state) => const JoinOrSearchClassScreen(),
      ),
      GoRoute(
        path: '/join-by-code',
        builder: (context, state) => const JoinByCodeScreen(),
      ),
      GoRoute(
        path: '/search-class',
        builder: (context, state) => const SearchClassScreen(),
      ),
      GoRoute(
        path: '/create-class',
        builder: (context, state) => const CreateClassScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = authState.isLoading;
      final user = authState.value;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-email';
      final isJoinRoute =
          state.matchedLocation == '/join-class-choice' ||
          state.matchedLocation == '/join-by-code' ||
          state.matchedLocation == '/search-class' ||
          state.matchedLocation == '/create-class';

      if (isLoading) {
        return null;
      }

      if (user == null && !isAuthRoute) {
        return '/login';
      }

      if (user != null && isAuthRoute) {
        return currentClass == null ? '/join-class-choice' : '/home';
      }

      if (user != null &&
          currentClass == null &&
          !isJoinRoute &&
          state.matchedLocation == '/home') {
        return '/join-class-choice';
      }

      return null;
    },
  );
});
