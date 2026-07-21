import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';

class SchedulePlannerView extends ConsumerWidget {
  const SchedulePlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dailyScheduleAsync = ref.watch(dailyScheduleProvider);

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final headerDateText = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = [
      {'code': 'mon', 'label': 'Mon', 'date': '${mondayOfThisWeek.day}'},
      {'code': 'tue', 'label': 'Tue', 'date': '${mondayOfThisWeek.add(const Duration(days: 1)).day}'},
      {'code': 'wed', 'label': 'Wed', 'date': '${mondayOfThisWeek.add(const Duration(days: 2)).day}'},
      {'code': 'thu', 'label': 'Thu', 'date': '${mondayOfThisWeek.add(const Duration(days: 3)).day}'},
      {'code': 'fri', 'label': 'Fri', 'date': '${mondayOfThisWeek.add(const Duration(days: 4)).day}'},
      {'code': 'sat', 'label': 'Sat', 'date': '${mondayOfThisWeek.add(const Duration(days: 5)).day}'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Planner Header
          Text(
            'Planner',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            headerDateText,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal Day Selector
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day['code'] == selectedDay;

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedDayProvider.notifier).select(day['code']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 76,
                    height: isSelected ? 96 : 88,
                    transform: isSelected
                        ? Matrix4.translationValues(0.0, -4.0, 0.0)
                        : Matrix4.identity(),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                        const SizedBox(height: 6),
                        Text(
                          day['date']!,
                          style: AppTypography.textTheme.headlineSmall
                              ?.copyWith(
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Daily Schedule Content List
          dailyScheduleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) =>
                Center(child: Text('Error loading schedule: $err')),
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 16, height: 16),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 40,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No classes scheduled for today.',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
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
    final accentColor = AppColors.getSubjectAccentColor(item.subjectCode, isBreak: true);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.outlineVariant,
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 2),
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

    final accentColor = AppColors.getSubjectAccentColor(item.subjectCode, isBreak: item.isBreak);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 6),
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
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
              const SizedBox(height: 12),
              Text(
                item.title,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 14),
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
                    const SizedBox(width: 6),
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
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.room,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
