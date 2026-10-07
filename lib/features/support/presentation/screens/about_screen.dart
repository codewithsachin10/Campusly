import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'About Campusly',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            // Campusly Logo & Badge
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.graduationCap,
                size: 56,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              'CAMPUSLY',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Version 2.4.0 (Build 2026.07 - Stable)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            Text(
              'Next-Generation Smart Campus Experience & Unified Academic Operating System tailored for Rajalakshmi Engineering College (REC).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5.h,
              ),
            ),
            SizedBox(height: 32.h),

            // Feature Highlights
            _buildInfoSection(
              context,
              title: 'Core Ecosystem Features',
              items: [
                _buildInfoTile(
                  context,
                  LucideIcons.calendarClock,
                  'Intelligent Timetable',
                  'Real-time lecture schedules, room swaps & live attendance tracking.',
                ),
                _buildInfoTile(
                  context,
                  LucideIcons.zap,
                  'Hackathons & Events Hub',
                  'One-tap registrations and live countdowns for technical fests.',
                ),
                _buildInfoTile(
                  context,
                  LucideIcons.bellRing,
                  'Targeted Push Alerts',
                  'Department and section-level instant notices & circulars.',
                ),
                _buildInfoTile(
                  context,
                  LucideIcons.map,
                  'Interactive Campus Map',
                  'Real-time floor directory & indoor navigation across academic blocks.',
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Institution & Credits
            _buildInfoSection(
              context,
              title: 'Institution & Developers',
              items: [
                _buildInfoTile(
                  context,
                  LucideIcons.building,
                  'Institution',
                  'Rajalakshmi Engineering College (Autonomous), Chennai.',
                ),
                _buildInfoTile(
                  context,
                  LucideIcons.code2,
                  'Designed & Engineered by',
                  'Sachin Gopalakrishnan (CSBS Dept) & Campusly Core Team.',
                ),
                _buildInfoTile(
                  context,
                  LucideIcons.shieldCheck,
                  'Security & Privacy',
                  'End-to-end encrypted student records with Supabase PostgreSQL infrastructure.',
                ),
              ],
            ),
            SizedBox(height: 36.h),

            Text(
              '© 2026 Campusly Systems. All rights reserved.\nMade with ❤️ for students & faculty.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5.h,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16.h),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
