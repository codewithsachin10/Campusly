import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';

class _CourseData {
  final TimetableItem item;
  final String details;
  final Color color;

  const _CourseData({
    required this.item,
    required this.details,
    required this.color,
  });

  String get title => item.title;
  String get instructor => item.instructor;
}

class CoursesShellView extends ConsumerWidget {
  const CoursesShellView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentClass = ref.watch(currentClassProvider);
    final joinedCustomTimetablesAsync = ref.watch(joinedCustomTimetablesProvider);
    final weeklyScheduleAsync = ref.watch(weeklyScheduleProvider);

    final items = weeklyScheduleAsync.value ?? [];
    final Map<String, _CourseData> coursesMap = {};
    final colors = [AppColors.primary, AppColors.secondary, AppColors.tertiary];
    int colorIndex = 0;

    for (final item in items) {
      if (item.isBreak) continue;
      if (!coursesMap.containsKey(item.title)) {
        final count = items.where((i) => i.title == item.title).length;
        final category = item.category.isNotEmpty && item.category != 'Break'
            ? item.category
            : 'Core Major';
        coursesMap[item.title] = _CourseData(
          item: item,
          details: '$count Units • $category',
          color: colors[colorIndex % colors.length],
        );
        colorIndex++;
      }
    }

    List<_CourseData> coursesList = coursesMap.values.toList();

    return Padding(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Courses',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enrolled in ${currentClass?.name ?? 'B.Tech CSBS - Section B'}',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: (currentClass == null && (joinedCustomTimetablesAsync.value == null || joinedCustomTimetablesAsync.value!.isEmpty))
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.graduationCap,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Class Joined',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Join or search for an academic section to see your courses.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          FilledButton.icon(
                            onPressed: () => context.push('/join-class-choice'),
                            icon: Icon(LucideIcons.search, size: 18),
                            label: Text('Find a Class'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : coursesList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No courses found for this class.',
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Subjects will appear once classes are scheduled in your timetable.',
                          textAlign: TextAlign.center,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: coursesList.length,
                    separatorBuilder: (_, _) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final course = coursesList[index];
                      return _buildCourseItem(context, course);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, _CourseData course) {
    return InkWell(
      onTap: () {
        SubjectDetailPage.navigate(context, course.item);
      },
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54.w,
              height: 54.h,
              decoration: BoxDecoration(
                color: course.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: course.color,
                size: 28,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${course.instructor} · ${course.details}',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksShellView extends StatelessWidget {
  const TasksShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks & Deadlines',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Stay on top of assignments and lab reports',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 48,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No tasks or deadlines assigned right now.',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'When instructors publish assignments or lab submissions, they will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
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
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
              style: AppTypography.textTheme.headlineLarge?.copyWith(
                color: AppColors.onPrimary,
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            user?.name ?? 'Sachin Gopalakrishnan',
            style: AppTypography.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            user?.email ?? 'sachin@campusly.edu',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.r),
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
                Divider(height: 32.h),
                _buildProfileRow(
                  Icons.pin_outlined,
                  'Class Code',
                  currentClass?.code ?? 'CAMPUS-B7K2',
                ),
                Divider(height: 32.h),
                _buildProfileRow(
                  Icons.apartment_rounded,
                  'Department',
                  user?.department ?? 'Computer Science',
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              foregroundColor: AppColors.error,
              elevation: 0,
              minimumSize: Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: Icon(Icons.logout_rounded),
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
        SizedBox(width: 16.w),
        Text(
          label,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Spacer(),
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
