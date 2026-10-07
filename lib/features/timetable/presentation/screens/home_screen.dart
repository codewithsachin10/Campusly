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
import '../widgets/campusly_side_drawer.dart';
import '../providers/timetable_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../../../../core/services/sync_engine_service.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/app_haptics.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';
import '../widgets/home_app_bar.dart';

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
      drawer: CampuslySideDrawer(
        onSelectTab: (index) {
          if (_selectedIndex != index) {
            AppHaptics.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.45,
      appBar: HomeAppBar(
        onOpenDrawer: () => Scaffold.of(context).openDrawer(),
        onOpenProfile: () {
          if (_selectedIndex != 4) {
            AppHaptics.selectionClick();
            setState(() {
              _selectedIndex = 4;
            });
          }
        },
      ),
      body: LazyIndexedStack(
        index: _selectedIndex,
        itemCount: 5,
        itemBuilder: _buildTab,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/inbox');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        child: Icon(Icons.chat_bubble_outline_rounded),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (_selectedIndex != index) {
              AppHaptics.selectionClick();
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.calendar_today_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
              ),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.menu_book_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
              ),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.fact_check_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.fact_check_rounded,
                color: AppColors.primary,
              ),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
                color: AppColors.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
