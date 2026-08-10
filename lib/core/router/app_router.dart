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
import '../../features/events/domain/models/event_model.dart';
import '../../features/connect/presentation/screens/people_directory_screen.dart';
import '../../features/presence/presentation/screens/campus_presence_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/events_home_screen.dart';
import '../../features/notifications/presentation/screens/notification_inbox_screen.dart';
import '../../features/notifications/presentation/screens/class_change_alert_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/chat/presentation/screens/inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/create_group_screen.dart';
import '../../features/timetable/presentation/screens/home_screen.dart';

import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/timetable/presentation/screens/exam_timetables_screen.dart';
import '../../features/timetable/presentation/screens/exam_venues_screen.dart';
import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/campus/presentation/screens/campus_map_screen.dart';
import '../../features/support/presentation/screens/helpdesk_screen.dart';
import '../../features/support/presentation/screens/about_screen.dart';

import '../../features/profile/presentation/screens/complete_profile_screen.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';

export 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final currentClass = ref.watch(currentClassProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
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
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsHomeScreen(),
      ),
      GoRoute(
        path: '/events/detail',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventDetailScreen(event: event);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationInboxScreen(),
      ),
      GoRoute(
        path: '/notifications/alert',
        builder: (context, state) {
          final payload = state.extra as String? ?? '{}';
          return ClassChangeAlertScreen(payload: payload);
        },
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(path: '/inbox', builder: (context, state) => const InboxScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          final chatTitle = state.uri.queryParameters['title'] ?? 'Chat';
          return ChatScreen(chatId: chatId, chatTitle: chatTitle);
        },
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/people-directory',
        builder: (context, state) => const PeopleDirectoryScreen(),
      ),
      GoRoute(
        path: '/campus-presence',
        builder: (context, state) => const CampusPresenceScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/exam-timetables',
        builder: (context, state) => const ExamTimeTablesScreen(),
      ),
      GoRoute(
        path: '/exam-venues',
        builder: (context, state) => const ExamVenuesScreen(),
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/campus-map',
        builder: (context, state) => const CampusMapScreen(),
      ),
      GoRoute(
        path: '/helpdesk',
        builder: (context, state) => const HelpdeskScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),

    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = authState.isLoading;
      final user = authState.value;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-email';
          
      final isCompleteProfileRoute = state.matchedLocation == '/complete-profile';

      final isJoinRoute =
          state.matchedLocation == '/join-class-choice' ||
          state.matchedLocation == '/join-by-code' ||
          state.matchedLocation == '/search-class' ||
          state.matchedLocation == '/create-class';

      final isSplashRoute = state.matchedLocation == '/splash';
      if (isSplashRoute) return null;

      if (isLoading) {
        return null;
      }

      if (user == null && !isAuthRoute) {
        return '/login';
      }
      
      if (user != null) {
        if (!user.isProfileCompleted && !isCompleteProfileRoute) {
          return '/complete-profile';
        }
        if (user.isProfileCompleted && isCompleteProfileRoute) {
          return '/home';
        }
      }

      if (user != null && isAuthRoute) {
        if (!user.isProfileCompleted) return '/complete-profile';
        return '/home';
      }

      return null;
    },
  );
});
