import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'About Campusly',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Campusly Logo & Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.graduationCap,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'CAMPUSLY',
              style: AppTypography.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 2.4.0 (Build 2026.07 - Stable)',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Next-Generation Smart Campus Experience & Unified Academic Operating System tailored for Rajalakshmi Engineering College (REC).',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Feature Highlights
            _buildInfoSection(
              title: 'Core Ecosystem Features',
              items: [
                _buildInfoTile(
                  LucideIcons.calendarClock,
                  'Intelligent Timetable',
                  'Real-time lecture schedules, room swaps & live attendance tracking.',
                ),
                _buildInfoTile(
                  LucideIcons.zap,
                  'Hackathons & Events Hub',
                  'One-tap registrations and live countdowns for technical fests.',
                ),
                _buildInfoTile(
                  LucideIcons.bellRing,
                  'Targeted Push Alerts',
                  'Department and section-level instant notices & circulars.',
                ),
                _buildInfoTile(
                  LucideIcons.map,
                  'Interactive Campus Map',
                  'Real-time floor directory & indoor navigation across academic blocks.',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Institution & Credits
            _buildInfoSection(
              title: 'Institution & Developers',
              items: [
                _buildInfoTile(
                  LucideIcons.building,
                  'Institution',
                  'Rajalakshmi Engineering College (Autonomous), Chennai.',
                ),
                _buildInfoTile(
                  LucideIcons.code2,
                  'Designed & Engineered by',
                  'Sachin Gopalakrishnan (CSBS Dept) & Campusly Core Team.',
                ),
                _buildInfoTile(
                  LucideIcons.shieldCheck,
                  'Security & Privacy',
                  'End-to-end encrypted student records with Supabase PostgreSQL infrastructure.',
                ),
              ],
            ),
            const SizedBox(height: 36),

            Text(
              '© 2026 Campusly Systems. All rights reserved.\nMade with ❤️ for students & faculty.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
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
