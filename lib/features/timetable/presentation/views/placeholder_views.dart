import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';

class CoursesShellView extends ConsumerWidget {
  const CoursesShellView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentClass = ref.watch(currentClassProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Courses',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enrolled in ${currentClass?.name ?? 'B.Tech CSE - Section A'}',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildCourseItem(
                  'Object Oriented Programming using Java',
                  'Dr. Sarah Chen',
                  '4 Units • Lab Included',
                  AppColors.primary,
                ),
                const SizedBox(height: 16),
                _buildCourseItem(
                  'Database Technology',
                  'Rajammal K',
                  '3 Units • Core Major',
                  AppColors.secondary,
                ),
                const SizedBox(height: 16),
                _buildCourseItem(
                  'Data Structures & Algorithms',
                  'Prof. Miller',
                  '4 Units • Core Major',
                  AppColors.tertiary,
                ),
                const SizedBox(height: 16),
                _buildCourseItem(
                  'Cloud Computing & Virtualization',
                  'Dr. James Wilson',
                  '3 Units • Elective',
                  AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(
    String title,
    String instructor,
    String details,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.menu_book_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$instructor · $details',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
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

class TasksShellView extends StatelessWidget {
  const TasksShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks & Deadlines',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay on top of assignments and lab reports',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildTaskCard(
                  'OOP Java Lab Report #4',
                  'Due Today, 11:59 PM',
                  true,
                ),
                const SizedBox(height: 14),
                _buildTaskCard(
                  'Database Normalization Assignment',
                  'Due Wed, Jul 22',
                  false,
                ),
                const SizedBox(height: 14),
                _buildTaskCard(
                  'Cloud Virtualization Mini-Project Proposal',
                  'Due Fri, Jul 24',
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String deadline, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant, width: 2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: isUrgent
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
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

class ProfileShellView extends ConsumerWidget {
  const ProfileShellView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
              style: AppTypography.textTheme.headlineLarge?.copyWith(
                color: AppColors.onPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Sachin Gopalakrishnan',
            style: AppTypography.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'sachin@campusly.edu',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildProfileRow(
                  Icons.school_rounded,
                  'Active Class',
                  currentClass?.name ?? 'B.Tech CSE - Section A',
                ),
                const Divider(height: 32),
                _buildProfileRow(
                  Icons.pin_outlined,
                  'Class Code',
                  currentClass?.code ?? 'CAMPUS-B7K2',
                ),
                const Divider(height: 32),
                _buildProfileRow(
                  Icons.apartment_rounded,
                  'Department',
                  user?.department ?? 'Computer Science',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              foregroundColor: AppColors.error,
              elevation: 0,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              'Sign Out',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 16),
        Text(
          label,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
