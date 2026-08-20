import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Student Profile',
                  style: AppTypography.textTheme.headlineLarge?.copyWith(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettingsScreen()),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  padding: EdgeInsets.all(12.w),
                ),
                icon: Icon(
                  Icons.settings_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Settings & Notifications',
              ),
            ],
          ),
          SizedBox(height: 24.h),

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
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
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
                        style: AppTypography.textTheme.headlineLarge?.copyWith(
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
                                  style: AppTypography.textTheme.headlineSmall
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
                              style: AppTypography.textTheme.labelMedium
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
                            style: AppTypography.textTheme.bodySmall?.copyWith(
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
                            style: AppTypography.textTheme.labelSmall
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
                            style: AppTypography.textTheme.titleMedium
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
                          style: AppTypography.textTheme.labelLarge?.copyWith(
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
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              _buildStatCard(
                icon: Icons.fact_check_rounded,
                color: AppColors.secondary,
                label: 'Attendance Target',
                value: '85.0%',
                subtitle: 'On Track (18/20 classes)',
              ),
              _buildStatCard(
                icon: Icons.auto_stories_rounded,
                color: AppColors.primary,
                label: 'Enrolled Subjects',
                value: '6 Core',
                subtitle: 'Plus 2 Lab Practicals',
              ),
              _buildStatCard(
                icon: Icons.schedule_rounded,
                color: AppColors.tertiary,
                label: 'Weekly Workload',
                value: '24 Hrs',
                subtitle: 'Mon — Fri Timetable',
              ),
              _buildStatCard(
                icon: Icons.cloud_done_rounded,
                color: AppColors.onSurfaceVariant,
                label: 'Offline Engine',
                value: 'Ready',
                subtitle: 'Local SQLite/Storage Sync',
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // Menu Navigation Section
          Text(
            'ACCOUNT & PREFERENCES',
            style: AppTypography.textTheme.labelMedium?.copyWith(
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
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
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
        style: AppTypography.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.textTheme.bodySmall?.copyWith(
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
