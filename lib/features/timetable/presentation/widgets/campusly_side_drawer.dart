import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
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
                left: 20.w,
                right: 20.w,
                bottom: 24.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2.5.w,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
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
                            Icon(
                              LucideIcons.edit3,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          currentClass?.name ?? 'No active class enrolled',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
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
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              children: [
                // 2. Timetable Sub-menu (Exam TimeTables & Exam Venues)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
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
                    childrenPadding: EdgeInsets.only(left: 20.w, bottom: 4.h),
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
                SizedBox(height: 4.h),

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
                        builder: (context) => CurriculumScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 4.h),

                // 4. Events & Hackathons Hub
                _buildMenuItem(
                  context,
                  icon: LucideIcons.zap,
                  iconColor: Color(0xFF571AC0),
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
                  iconColor: Color(0xFF0058BE),
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
                  iconColor: Color(0xFFED6C02),
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
                  iconColor: Color(0xFF2E7D32),
                  title: 'Campus Interactive Map',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/campus-map');
                  },
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Divider(height: 1.h),
                ),

                // 8. Theme & Appearance: Toggle Dark / Light Mode
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 4.h,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Color(0xFFADC6FF).withValues(alpha: 0.15)
                              : AppColors.primaryContainer.withValues(
                                  alpha: 0.15,
                                ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          isDark ? LucideIcons.moon : LucideIcons.sun,
                          color: isDark
                              ? Color(0xFFADC6FF)
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 14.w),
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
                                fontSize: 11.sp,
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
                SizedBox(height: 4.h),

                // 9. Student Helpdesk & IT Support
                _buildMenuItem(
                  context,
                  icon: LucideIcons.headset,
                  iconColor: Color(0xFF26A69A),
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
                SizedBox(height: 4.h),

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
            padding: EdgeInsets.all(16.w),
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
                    title: Text('Sign Out of Campusly?'),
                    content: Text(
                      'You will need to log in again to access your academic timetable and notifications.',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel'),
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
                        icon: Icon(LucideIcons.logOut, size: 16),
                        label: Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.logOut,
                      color: AppColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 14.w),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
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
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: badge == 'LIVE'
                    ? Color(0xFF571AC0)
                    : AppColors.error,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      leading: Icon(icon, size: 18, color: AppColors.textSecondary),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}
