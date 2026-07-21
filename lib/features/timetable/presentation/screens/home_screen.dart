import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../views/home_dashboard_view.dart';
import '../views/schedule_planner_view.dart';
import '../views/placeholder_views.dart';
import '../views/attendance_dashboard_view.dart';
import '../providers/timetable_provider.dart';
import '../../domain/models/timetable_item.dart';

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
    // Initialize system notification engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      final currentVersionName = packageInfo.version;

      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('app_config').doc('update');

      // 1. Auto-seed config if missing
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        final initialConfig = {
          'latestVersionCode': currentVersionCode,
          'latestVersionName': currentVersionName,
          'critical': false,
          'apkUrl': 'https://github.com/codewithsachin10/REC_RESULT/releases',
          'releaseNotes': 'Initial release of Campusly Companion App!',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(initialConfig);
        return;
      }

      final data = docSnap.data();
      if (data == null) return;

      final latestVersionCode = data['latestVersionCode'] as int? ?? currentVersionCode;
      final latestVersionName = data['latestVersionName'] as String? ?? currentVersionName;
      final critical = data['critical'] as bool? ?? false;
      final apkUrlStr = data['apkUrl'] as String? ?? '';
      final releaseNotes = data['releaseNotes'] as String? ?? '';

      if (latestVersionCode > currentVersionCode && apkUrlStr.isNotEmpty) {
        final Uri apkUri = Uri.parse(apkUrlStr);
        if (critical) {
          _showCriticalUpdateDialog(latestVersionName, apkUri, releaseNotes);
        } else {
          _showFlexibleUpdateSnackBar(latestVersionName, apkUri);
        }
      }
    } catch (e) {
      debugPrint('Custom in-app update check failed: $e');
    }
  }

  void _showCriticalUpdateDialog(String version, Uri apkUri, String releaseNotes) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.system_update_rounded, color: AppColors.error, size: 28),
                SizedBox(width: 12),
                Text('Mandatory Update', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A critical new update (v$version) is required to continue using Campusly.'),
                const SizedBox(height: 12),
                if (releaseNotes.isNotEmpty) ...[
                  const Text('What\'s new:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    releaseNotes,
                    style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Please install the update to proceed.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (await canLaunchUrl(apkUri)) {
                    await launchUrl(apkUri, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFlexibleUpdateSnackBar(String version, Uri apkUri) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update v$version is available!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(days: 365),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        action: SnackBarAction(
          label: 'DOWNLOAD',
          textColor: Colors.amber,
          onPressed: () async {
            if (await canLaunchUrl(apkUri)) {
              await launchUrl(apkUri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);

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
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campusly',
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (currentClass != null)
                  Text(
                    currentClass.code,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            tooltip: 'Class Reminders & Notification Settings',
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
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
