import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/system_notifications_watcher.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../views/home_dashboard_view.dart';
import '../views/schedule_planner_view.dart';
import '../views/placeholder_views.dart';
import '../views/attendance_dashboard_view.dart';
import '../widgets/campusly_side_drawer.dart';
import '../providers/timetable_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../../../chat/presentation/widgets/sync_status_indicator.dart';
import '../../../../core/services/sync_engine_service.dart';
import '../../../../core/services/presence_service.dart';
import '../../../updater/data/services/version_check_service.dart';
import '../../../updater/presentation/views/update_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

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
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final versionService = ref.read(versionCheckServiceProvider);
      final result = await versionService.checkForUpdates();
      
      if (result.updateAvailable && result.releaseInfo != null) {
        if (!mounted) return;
        final isMandatory = result.releaseInfo!.updateType == UpdateType.MANDATORY;
        showDialog(
          context: context,
          barrierDismissible: !isMandatory,
          builder: (ctx) => UpdateDialog(
            releaseInfo: result.releaseInfo!,
          ),
        );
      }
    } catch (e) {
      debugPrint('Smart in-app update check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // Initialize SyncEngine (offline background processing)
    ref.watch(syncEngineProvider);

    // Initialize Realtime Presence Tracking
    ref.watch(presenceServiceProvider);

    // Watch real-time system notifications engine (triggers status bar alerts for new notices)
    ref.watch(systemNotificationsWatcherProvider);

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

    final views = [
      HomeDashboardView(
        onNavigateToSchedule: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      const SchedulePlannerView(),
      const CoursesShellView(),
      const AttendanceDashboardView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: CampuslySideDrawer(
        onSelectTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.45,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'Open Side Navigation Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campusly',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (currentClass != null)
                    Text(
                      currentClass.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Global Sync Status
          Center(child: SyncStatusIndicator()),
          const SizedBox(width: 8),

          // Class switcher button
          IconButton(
            onPressed: () {
              context.push('/join-class-choice');
            },
            tooltip: 'Switch or Join Class',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          // Notification icon
          IconButton(
            onPressed: () {
              context.push('/notifications');
            },
            tooltip: 'Notification Center',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 26,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Profile Avatar
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 4; // Navigate to Profile tab
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'S',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: views),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/inbox');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        child: const Icon(Icons.chat_bubble_outline_rounded),
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
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
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
