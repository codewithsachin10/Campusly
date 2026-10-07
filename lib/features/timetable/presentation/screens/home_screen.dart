import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/home_widget_service.dart';
import '../../../../core/services/system_notifications_watcher.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../views/home_dashboard_view.dart';
import '../views/schedule_planner_view.dart';
import '../views/placeholder_views.dart';
import '../views/attendance_dashboard_view.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../providers/timetable_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../../../../core/services/sync_engine_service.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/app_haptics.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';

final _appServicesInitProvider = Provider<void>((ref) {
  ref.watch(syncEngineProvider);
  ref.watch(presenceServiceProvider);
  ref.watch(systemNotificationsWatcherProvider);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _homeWidgetDebounceTimer;

  @override
  void dispose() {
    _homeWidgetDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize system notification engine and click listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifService = ref.read(notificationServiceProvider);
      notifService.init();
      notifService.onNotificationClick.stream.listen((payload) {
        if (!mounted) return;
        if (payload == 'notification_inbox') {
          context.push('/notifications');
        } else if (payload == 'announcements') {
          context.push('/announcements');
        }
      });
    });
  }

  Widget _buildTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        return HomeDashboardView(
          onNavigateToSchedule: () {
            if (_selectedIndex != 1) {
              AppHaptics.selectionClick();
              setState(() {
                _selectedIndex = 1;
              });
            }
          },
        );
      case 1:
        return const SchedulePlannerView();
      case 2:
        return const CoursesShellView();
      case 3:
        return const AttendanceDashboardView();
      case 4:
        return const ProfileView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep background sync, presence, and system notification engines alive without rebuilding shell
    ref.listen(_appServicesInitProvider, (previous, next) {});

    // Debounced HomeWidget update on schedule snapshot change
    ref.listen(widgetScheduleSnapshotProvider, (previous, next) {
      _homeWidgetDebounceTimer?.cancel();
      _homeWidgetDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        HomeWidgetService().updateWidgetData(
          ongoingClass: next.ongoing,
          nextClass: next.next,
        );
      });
    });

    // Schedule notifications whenever weekly schedule or preferences change
    ref.listen<AsyncValue<List<TimetableItem>>>(weeklyScheduleProvider, (
      previous,
      next,
    ) {
      next.whenData((items) {
        final prefs = ref.read(notificationPreferencesProvider);
        ref
            .read(notificationServiceProvider)
            .scheduleClassReminders(items, prefs);
      });
    });

    ref.listen<NotificationPreferences>(notificationPreferencesProvider, (
      previous,
      next,
    ) {
      final weeklySchedule = ref.read(weeklyScheduleProvider).value;
      if (weeklySchedule != null) {
        ref
            .read(notificationServiceProvider)
            .scheduleClassReminders(weeklySchedule, next);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: LazyIndexedStack(
        index: _selectedIndex,
        itemCount: 5,
        itemBuilder: _buildTab,
      ),
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (_selectedIndex != index) {
            AppHaptics.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          FloatingPillNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          FloatingPillNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: 'Schedule',
          ),
          FloatingPillNavItem(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book_rounded,
            label: 'Courses',
          ),
          FloatingPillNavItem(
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check_rounded,
            label: 'Attendance',
          ),
          FloatingPillNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
