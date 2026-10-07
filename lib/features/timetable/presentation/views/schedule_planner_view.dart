import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/more_bottom_sheet.dart';
import '../widgets/dynamic_schedule_card.dart';

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
            'Schedule',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/join-class-choice'),
              tooltip: 'Switch or Join Class',
              icon: Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
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
                Text(
                  headerDateText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 20.h),

          // Horizontal Day Selector (Clean text tabs, no heavy cards)
          SizedBox(
            height: 48.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day['code'] == selectedDay;

                return InkWell(
                  onTap: () {
                    ref.read(selectedDayProvider.notifier).select(day['code']!);
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.1))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1.2,
                            )
                          : Border.all(
                              color: isDark
                                  ? AppColors.darkOutlineVariant.withValues(alpha: 0.25)
                                  : AppColors.outlineVariant.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day['label']!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          day['date']!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24.h),

          // Daily Schedule Content List
          dailyScheduleAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0.h),
              child: const Center(
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
                return _buildEmptyState(context);
              }

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final currentMin = now.hour * 60 + now.minute;
                  final startMin = item.startHour * 60 + item.startMinute;
                  final endMin = item.endHour * 60 + item.endMinute;
                  final isToday = weekdays[now.weekday - 1].toLowerCase().startsWith(selectedDay.toLowerCase());
                  final isCompleted = isToday && currentMin >= endMin;
                  final isCurrent = isToday && currentMin >= startMin && currentMin < endMin;

                  return DynamicScheduleCard(
                    item: item,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isFirst: index == 0,
                    isLast: index == items.length - 1,
                  );
                },
              );
            },
          ),
          SizedBox(height: 100.h),
        ],
      ),
    ),
  ),
],
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Join or search for an academic section to see your schedule.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildEmptyState(BuildContext context) {
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Enjoy your free day or work on self-paced projects!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }


}
