import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../../../timetable/presentation/widgets/more_bottom_sheet.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar.large(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          scrolledUnderElevation: 0,
          pinned: true,
          floating: false,
          leading: IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'More options',
            onPressed: () => MoreBottomSheet.show(context),
          ),
          title: Text(
            'Profile',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(
                Icons.settings_rounded,
                color: AppColors.primary,
              ),
              tooltip: 'Settings & Notifications',
            ),
            SizedBox(width: 8.w),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

          // Hero Profile Card
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 76.w,
                      height: 76.h,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.onPrimary,
                          width: 2.5.w,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'S',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name
                                      : 'Student Profile',
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.verified_rounded,
                                color: AppColors.tertiaryFixed,
                                size: 20,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              user?.department ?? 'Institutional Department',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            user?.email.isNotEmpty == true
                                ? user!.email
                                : 'No email address',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Active Class Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.class_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENROLLED ACADEMIC SECTION',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            currentClass != null
                                ? '${currentClass.name} · ${currentClass.section}'
                                : 'No active class enrolled',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Invite Code: ${currentClass?.code ?? "Not enrolled"}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (currentClass != null)
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: currentClass.code),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Class invite code copied to clipboard!',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Copy Code',
                        ),
                    ],
                  ),
                ),
                if (currentClass != null) ...[
                  SizedBox(height: 16.h),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: QrImageView(
                        data: currentClass.code,
                        version: QrVersions.auto,
                        size: 140.0,
                        gapless: false,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Center(
                    child: Text(
                      'Scan this QR code to join this class instantly',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/join-class-choice');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: Icon(Icons.swap_horiz_rounded, size: 20),
                    label: Text(
                      'Switch or Join Another Class',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Academic Summary Grid
          Text(
            'ACADEMIC OVERVIEW',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildStatTile(
                  context,
                  icon: Icons.fact_check_rounded,
                  color: AppColors.secondary,
                  label: 'Attendance Target',
                  value: '85.0%',
                  subtitle: 'On Track (18/20 classes)',
                ),
                Divider(height: 1.h, indent: 64.w, endIndent: 20.w),
                _buildStatTile(
                  context,
                  icon: Icons.auto_stories_rounded,
                  color: AppColors.primary,
                  label: 'Enrolled Subjects',
                  value: '6 Core',
                  subtitle: 'Plus 2 Lab Practicals',
                ),
                Divider(height: 1.h, indent: 64.w, endIndent: 20.w),
                _buildStatTile(
                  context,
                  icon: Icons.schedule_rounded,
                  color: AppColors.tertiary,
                  label: 'Weekly Workload',
                  value: '24 Hrs',
                  subtitle: 'Mon — Fri Timetable',
                ),
                Divider(height: 1.h, indent: 64.w, endIndent: 20.w),
                _buildStatTile(
                  context,
                  icon: Icons.cloud_done_rounded,
                  color: AppColors.mint,
                  label: 'Offline Engine',
                  value: 'Ready',
                  subtitle: 'Local SQLite/Storage Sync',
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // Menu Navigation Section
          Text(
            'ACCOUNT & PREFERENCES',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildMenuTile(
                  context,
                  icon: Icons.notifications_active_outlined,
                  iconColor: AppColors.primary,
                  title: 'System Notifications & Reminders',
                  subtitle: 'Configure 10-min & 15-min alerts before classes',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    );
                  },
                ),
                Divider(height: 1.h, indent: 60, endIndent: 20),
                _buildMenuTile(
                  context,
                  icon: Icons.person_search_rounded,
                  iconColor: AppColors.primary,
                  title: 'Edit Social Profile',
                  subtitle: 'Update your skills, interests, and visibility',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 1.h, indent: 60, endIndent: 20),
                _buildMenuTile(
                  context,
                  icon: Icons.tune_rounded,
                  iconColor: AppColors.secondary,
                  title: 'App Settings & Themes',
                  subtitle: 'Appearance, offline cache, and preferences',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    );
                  },
                ),
                Divider(height: 1.h, indent: 60, endIndent: 20),
                _buildMenuTile(
                  context,
                  icon: Icons.share_rounded,
                  iconColor: AppColors.tertiary,
                  title: 'Share Class Community',
                  subtitle: 'Invite classmates to sync with your schedule',
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: currentClass?.code ?? 'CAMPUS-B7K2'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invite link copied! Share with your classmates.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // Sign Out Action Button
          ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  title: Text('Sign Out of Campusly?'),
                  content: Text(
                    'Your offline timetable will stay preserved locally on this device until you sign back in.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                      ),
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              foregroundColor: AppColors.error,
              elevation: 0,
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
            icon: Icon(Icons.logout_rounded, size: 22),
            label: Text(
              'Sign Out of Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 100.h),
        ],
      ),
    ),
  ),
],
);
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
