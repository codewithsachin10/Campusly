import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/campus/presentation/screens/campus_map_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/create_group_screen.dart';
import '../../features/chat/presentation/screens/inbox_screen.dart';
import '../../features/class_join/presentation/providers/class_provider.dart';
import '../../features/class_join/presentation/screens/create_class_screen.dart';
import '../../features/class_join/presentation/screens/join_by_code_screen.dart';
import '../../features/class_join/presentation/screens/join_or_search_class_screen.dart';
import '../../features/class_join/presentation/screens/search_class_screen.dart';
import '../../features/connect/presentation/screens/people_directory_screen.dart';
import '../../features/events/domain/models/event_model.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/events_home_screen.dart';
import '../../features/forms/presentation/screens/form_renderer_screen.dart';
import '../../features/notifications/presentation/screens/class_change_alert_screen.dart';
import '../../features/notifications/presentation/screens/notification_inbox_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/presence/presentation/screens/campus_presence_screen.dart';
import '../../features/profile/presentation/screens/complete_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/support/presentation/screens/about_screen.dart';
import '../../features/support/presentation/screens/helpdesk_screen.dart';
import '../../features/timetable/presentation/screens/exam_timetables_screen.dart';
import '../../features/timetable/presentation/screens/exam_venues_screen.dart';
import '../../features/timetable/presentation/screens/home_screen.dart';
import '../../features/updater/presentation/screens/updates_screen.dart';
import 'app_transitions.dart';

export 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Listens to Riverpod state changes and notifies GoRouter without recreating it
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
    ref.listen(currentClassProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final email = state.extra as String?;
          return AppTransitions.slideFade(
            context: context,
            state: state,
            child: EmailVerificationScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: '/complete-profile',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          context: context,
          state: state,
          child: const CompleteProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/join-class-choice',
        pageBuilder: (context, state) => AppTransitions.slideUp(
          context: context,
          state: state,
          child: const JoinOrSearchClassScreen(),
        ),
      ),
      GoRoute(
        path: '/join-by-code',
        pageBuilder: (context, state) => AppTransitions.slideUp(
          context: context,
          state: state,
          child: const JoinByCodeScreen(),
        ),
      ),
      GoRoute(
        path: '/search-class',
        pageBuilder: (context, state) => AppTransitions.slideUp(
          context: context,
          state: state,
          child: const SearchClassScreen(),
        ),
      ),
      GoRoute(
        path: '/create-class',
        pageBuilder: (context, state) => AppTransitions.slideUp(
          context: context,
          state: state,
          child: const CreateClassScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          context: context,
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/events',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          context: context,
          state: state,
          child: const EventsHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/events/detail',
        pageBuilder: (context, state) {
          final event = state.extra as EventModel;
          return AppTransitions.slideFade(
            context: context,
            state: state,
            child: EventDetailScreen(event: event),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const NotificationInboxScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications/alert',
        pageBuilder: (context, state) {
          final payload = state.extra as String? ?? '{}';
          return AppTransitions.slideUp(
            context: context,
            state: state,
            child: ClassChangeAlertScreen(payload: payload),
          );
        },
      ),
      GoRoute(
        path: '/notifications/settings',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/inbox',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          context: context,
          state: state,
          child: const InboxScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['id']!;
          final chatTitle = state.uri.queryParameters['title'] ?? 'Chat';
          return AppTransitions.slideFade(
            context: context,
            state: state,
            child: ChatScreen(chatId: chatId, chatTitle: chatTitle),
          );
        },
      ),
      GoRoute(
        path: '/create-group',
        pageBuilder: (context, state) => AppTransitions.slideUp(
          context: context,
          state: state,
          child: const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: '/people-directory',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const PeopleDirectoryScreen(),
        ),
      ),
      GoRoute(
        path: '/campus-presence',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const CampusPresenceScreen(),
        ),
      ),
      GoRoute(
        path: '/profile-edit',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const ProfileEditScreen(),
        ),
      ),
      GoRoute(
        path: '/exam-timetables',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const ExamTimeTablesScreen(),
        ),
      ),
      GoRoute(
        path: '/exam-venues',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const ExamVenuesScreen(),
        ),
      ),
      GoRoute(
        path: '/announcements',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const AnnouncementsScreen(),
        ),
      ),
      GoRoute(
        path: '/campus-map',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const CampusMapScreen(),
        ),
      ),
      GoRoute(
        path: '/helpdesk',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const HelpdeskScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/form/:token',
        pageBuilder: (context, state) {
          final token = state.pathParameters['token']!;
          return AppTransitions.slideUp(
            context: context,
            state: state,
            child: FormRendererScreen(formToken: token),
          );
        },
      ),
      GoRoute(
        path: '/updates',
        pageBuilder: (context, state) => AppTransitions.slideFade(
          context: context,
          state: state,
          child: const UpdatesScreen(),
        ),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final isLoading = authState.isLoading;
      final user = authState.value;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-email';

      final isCompleteProfileRoute =
          state.matchedLocation == '/complete-profile';

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
