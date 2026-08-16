import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../features/curriculum/presentation/screens/curriculum_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';

class CampuslySideDrawer extends ConsumerWidget {
  final Function(int)? onSelectTab;

  const CampuslySideDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      backgroundColor: AppColors.surface,
      elevation: 16,
      child: Column(
        children: [
          // 1. Student Profile Header
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              context.push('/profile-edit');
            },
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name
                                    : 'Student Profile',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              LucideIcons.edit3,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentClass?.name ?? 'No active class enrolled',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email.isNotEmpty == true
                              ? user!.email
                              : 'No email address',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                // 2. Timetable Sub-menu (Exam TimeTables & Exam Venues)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.calendar,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'TimeTable & Exams',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.only(left: 20, bottom: 4),
                    children: [
                      _buildSubMenuItem(
                        context,
                        icon: LucideIcons.calendarClock,
                        title: 'Exam TimeTables',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/exam-timetables');
                        },
                      ),
                      _buildSubMenuItem(
                        context,
                        icon: LucideIcons.mapPin,
                        title: 'Exam Venues & Seating',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/exam-venues');
                        },
                      ),
                      _buildSubMenuItem(
                        context,
                        icon: LucideIcons.qrCode,
                        title: 'Join Custom Timetable',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/join-class-choice');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Curriculum
                _buildMenuItem(
                  context,
                  icon: Icons.menu_book_rounded,
                  iconColor: AppColors.primary,
                  title: 'Curriculum',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CurriculumScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // 4. Events & Hackathons Hub
                _buildMenuItem(
                  context,
                  icon: LucideIcons.zap,
                  iconColor: const Color(0xFF571AC0),
                  title: 'Events & Hackathons Hub',
                  badge: 'LIVE',
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onSelectTab != null) {
                      onSelectTab!(3); // Switch to Events Tab
                    } else {
                      context.push('/events');
                    }
                  },
                ),

                // 5. Notice Board & Circulars
                _buildMenuItem(
                  context,
                  icon: LucideIcons.megaphone,
                  iconColor: const Color(0xFF0058BE),
                  title: 'Notice Board & Circulars',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/announcements');
                  },
                ),

                // 6. Notification Inbox
                _buildMenuItem(
                  context,
                  icon: LucideIcons.bellRing,
                  iconColor: const Color(0xFFED6C02),
                  title: 'Notification Inbox',
                  badge: '3',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/notifications');
                  },
                ),

                // 7. Campus Interactive Map
                _buildMenuItem(
                  context,
                  icon: LucideIcons.map,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Campus Interactive Map',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/campus-map');
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                // 8. Theme & Appearance: Toggle Dark / Light Mode
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFADC6FF).withValues(alpha: 0.15)
                              : AppColors.primaryContainer.withValues(
                                  alpha: 0.15,
                                ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark ? LucideIcons.moon : LucideIcons.sun,
                          color: isDark
                              ? const Color(0xFFADC6FF)
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              isDark
                                  ? 'Appearance: Dark Theme'
                                  : 'Appearance: Light Theme',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isDark,
                        activeTrackColor: AppColors.primary,
                        onChanged: (value) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // 9. Student Helpdesk & IT Support
                _buildMenuItem(
                  context,
                  icon: LucideIcons.headset,
                  iconColor: const Color(0xFF26A69A),
                  title: 'Student Helpdesk & Support',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/helpdesk');
                  },
                ),

                // 10. About Campusly
                _buildMenuItem(
                  context,
                  icon: LucideIcons.info,
                  iconColor: AppColors.outline,
                  title: 'About Campusly',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/about');
                  },
                ),
                const SizedBox(height: 4),

                // 11. Updates Center
                _buildMenuItem(
                  context,
                  icon: LucideIcons.downloadCloud,
                  iconColor: AppColors.primary,
                  title: 'Updates Center',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/updates');
                  },
                ),
              ],
            ),
          ),

          // 11. Sign Out Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: InkWell(
              onTap: () async {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out of Campusly?'),
                    content: const Text(
                      'You will need to log in again to access your academic timetable and notifications.',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.logOut,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Sign Out',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    String? badge,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badge == 'LIVE'
                    ? const Color(0xFF571AC0)
                    : AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSecondary,
            ),
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(icon, size: 18, color: AppColors.textSecondary),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}
