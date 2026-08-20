import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';

class SchedulePlannerView extends ConsumerWidget {
  const SchedulePlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dailyScheduleAsync = ref.watch(dailyScheduleProvider);
    final currentClass = ref.watch(currentClassProvider);
    final joinedCustomTimetablesAsync = ref.watch(joinedCustomTimetablesProvider);

    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final headerDateText =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = [
      {'code': 'mon', 'label': 'Mon', 'date': '${mondayOfThisWeek.day}'},
      {
        'code': 'tue',
        'label': 'Tue',
        'date': '${mondayOfThisWeek.add(Duration(days: 1)).day}',
      },
      {
        'code': 'wed',
        'label': 'Wed',
        'date': '${mondayOfThisWeek.add(Duration(days: 2)).day}',
      },
      {
        'code': 'thu',
        'label': 'Thu',
        'date': '${mondayOfThisWeek.add(Duration(days: 3)).day}',
      },
      {
        'code': 'fri',
        'label': 'Fri',
        'date': '${mondayOfThisWeek.add(Duration(days: 4)).day}',
      },
      {
        'code': 'sat',
        'label': 'Sat',
        'date': '${mondayOfThisWeek.add(Duration(days: 5)).day}',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Planner Header
          Text(
            'Planner',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            headerDateText,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),

          // Horizontal Day Selector
          SizedBox(
            height: 104.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (context, index) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day['code'] == selectedDay;

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedDayProvider.notifier).select(day['code']!);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 76.w,
                    height: isSelected ? 96 : 88,
                    transform: isSelected
                        ? Matrix4.translationValues(0.0, -4.0, 0.0)
                        : Matrix4.identity(),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day['label']!,
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? AppColors.onPrimary.withValues(alpha: 0.8)
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          day['date']!,
                          style: AppTypography.textTheme.headlineSmall
                              ?.copyWith(
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 22.sp,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 32.h),

          // Daily Schedule Content List
          dailyScheduleAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0.h),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) =>
                Center(child: Text('Error loading schedule: $err')),
            data: (items) {
              if (currentClass == null && (joinedCustomTimetablesAsync.value == null || joinedCustomTimetablesAsync.value!.isEmpty)) {
                return _buildNoClassJoinedState(context);
              }
              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: 16.w, height: 16.h),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.isBreak) {
                    return _buildBreakCard(item);
                  }
                  return _buildClassCard(item);
                },
              );
            },
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildNoClassJoinedState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 64.h, horizontal: 24.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.graduationCap,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No Class Joined',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Join or search for an academic section to see your schedule.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 64.h, horizontal: 24.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 40,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No classes scheduled for today.',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Enjoy your free day or work on self-paced projects!',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakCard(TimetableItem item) {
    final accentColor = AppColors.getSubjectAccentColor(
      item.subjectCode,
      isBreak: true,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: AppColors.outlineVariant,
          style: BorderStyle.solid,
          width: 1.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 6.w)),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.startTime} — ${item.endTime}',
                      style: AppTypography.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.title,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(TimetableItem item) {
    Color badgeBg;
    Color badgeText;

    switch (item.category.toLowerCase()) {
      case 'lab':
        badgeBg = AppColors.primary.withValues(alpha: 0.1);
        badgeText = AppColors.primary;
        break;
      case 'major':
        badgeBg = AppColors.secondary.withValues(alpha: 0.1);
        badgeText = AppColors.secondary;
        break;
      case 'elective':
        badgeBg = AppColors.tertiary.withValues(alpha: 0.1);
        badgeText = AppColors.tertiary;
        break;
      default:
        badgeBg = AppColors.surfaceContainerHigh;
        badgeText = AppColors.onSurface;
    }

    final accentColor = AppColors.getSubjectAccentColor(
      item.subjectCode,
      isBreak: item.isBreak,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 6.w)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.timeRange,
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: badgeText,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                item.title,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  height: 1.3.h,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.only(top: 14.h),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        item.instructor,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        item.room,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
