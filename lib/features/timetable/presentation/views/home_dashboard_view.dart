import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';
import '../widgets/announcements_banner.dart';

class HomeDashboardView extends ConsumerWidget {
  final VoidCallback onNavigateToSchedule;

  const HomeDashboardView({super.key, required this.onNavigateToSchedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final ongoingAsync = ref.watch(ongoingClassProvider);
    final nextAsync = ref.watch(nextClassProvider);
    final todayScheduleAsync = ref.watch(todayScheduleProvider);
    ref.watch(liveTickerProvider);

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

    final isWeekendOrEmpty =
        todayScheduleAsync.value == null ||
        todayScheduleAsync.value!.isEmpty;
    final todayItems = todayScheduleAsync.value ?? [];
    final classCount = todayItems.where((i) => !i.isBreak).length;
    final breakCount = todayItems.where((i) => i.isBreak).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Text(
            'Good morning, ${user?.name.split(' ').first ?? 'Sachin'} 👋',
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              fontSize: 28,
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
          const SizedBox(height: 16),
          const AnnouncementsBanner(),
          const SizedBox(height: 16),

          // Weekend / No Classes Today Banner
          if (isWeekendOrEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.weekend_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Classes Today! 🎉',
                    style: AppTypography.textTheme.headlineSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "It's a free day or the weekend! Relax, recharge, or catch up on self-paced projects.",
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Ongoing Class Card (Most Prominent)
          if (!isWeekendOrEmpty) ...[
            ongoingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (ongoing) {
                if (ongoing == null) return const SizedBox.shrink();

                final currentMin = now.hour * 60 + now.minute;
                final endMin = ongoing.endHour * 60 + ongoing.endMinute;
                final minsLeft = (endMin - currentMin).clamp(0, 999);

                final startMin = ongoing.startHour * 60 + ongoing.startMinute;
                final totalDur = endMin - startMin;
                final elapsed = currentMin - startMin;
                final progress =
                    totalDur > 0
                        ? (elapsed / totalDur * 100).clamp(0.0, 100.0)
                        : 0.0;

                final badgeColor =
                    ongoing.isBreak
                        ? const Color(0xFF26A69A)
                        : AppColors.primary;
                final accentBorderColor = AppColors.getSubjectAccentColor(
                  ongoing.subjectCode,
                  isBreak: ongoing.isBreak,
                );

                return InkWell(
                  onTap: () => !ongoing.isBreak ? SubjectDetailPage.navigate(context, ongoing) : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: accentBorderColor, width: 6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ongoing.isBreak
                                            ? 'ONGOING BREAK'
                                            : 'ONGOING CLASS',
                                        style: AppTypography.textTheme.labelMedium
                                            ?.copyWith(
                                              color: badgeColor,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Ends in $minsLeft mins',
                                  style: AppTypography.textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ongoing.title,
                              style: AppTypography.textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ongoing.timeRange,
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ongoing.room,
                                    style: AppTypography.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ongoing.isBreak
                                      ? 'Break Progress'
                                      : 'Course Progress',
                                  style: AppTypography.textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  '${progress.toInt()}%',
                                  style: AppTypography.textTheme.labelMedium
                                      ?.copyWith(
                                        color: badgeColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress / 100.0,
                                backgroundColor: AppColors.surfaceContainer,
                                color: badgeColor,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Next Class Timer Box
            nextAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (next) {
                final ongoing = ongoingAsync.value;
                if (next == null) {
                  if (ongoing == null && todayItems.isNotEmpty) {
                    // All classes completed for today
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALL CLASSES COMPLETED TODAY! 🌟',
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Great job! Have a restful evening.',
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                // Compute countdown or display day
                final currentSecs =
                    now.hour * 3600 + now.minute * 60 + now.second;
                final startSecs = next.startHour * 3600 + next.startMinute * 60;
                final isToday =
                    next.dayOfWeek.toLowerCase() == _getDayStr(now.weekday);
                final diffSecs = startSecs - currentSecs;

                String timerOrDateDisplay;
                if (isToday && diffSecs > 0) {
                  final h = (diffSecs ~/ 3600).toString().padLeft(2, '0');
                  final m = ((diffSecs % 3600) ~/ 60).toString().padLeft(
                    2,
                    '0',
                  );
                  final s = (diffSecs % 60).toString().padLeft(2, '0');
                  timerOrDateDisplay = '$h:$m:$s';
                } else {
                  timerOrDateDisplay =
                      '${_getDayLabel(next.dayOfWeek).toUpperCase()} • ${next.startTime}';
                }

                return InkWell(
                  onTap: () => !next.isBreak ? SubjectDetailPage.navigate(context, next) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.timer_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isToday && diffSecs > 0
                                      ? 'NEXT CLASS IN'
                                      : 'UPCOMING CLASS ON',
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timerOrDateDisplay,
                                  style: AppTypography.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize:
                                            (isToday && diffSecs > 0) ? 22 : 16,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Upcoming',
                                style: AppTypography.textTheme.labelSmall
                                    ?.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                next.shortTitle,
                                style: AppTypography.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Overview Section (2 Horizontal Cards)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$classCount',
                              style: AppTypography.textTheme.headlineLarge
                                  ?.copyWith(
                                    fontSize: 28,
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Classes',
                              style: AppTypography.textTheme.labelMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: AppColors.secondary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$breakCount',
                              style: AppTypography.textTheme.headlineLarge
                                  ?.copyWith(
                                    fontSize: 28,
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Free Periods',
                              style: AppTypography.textTheme.labelMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // Today's Schedule Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule",
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: onNavigateToSchedule,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Full Calendar',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isWeekendOrEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 48,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No classes scheduled for today.',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap Full Calendar to explore your weekly timetable.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...todayItems.map((item) {
              final currentMin = now.hour * 60 + now.minute;
              final startMin = item.startHour * 60 + item.startMinute;
              final endMin = item.endHour * 60 + item.endMinute;
              final isCompleted = currentMin >= endMin;
              final isCurrent = currentMin >= startMin && currentMin < endMin;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildDynamicScheduleCard(
                  context: context,
                  item: item,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                ),
              );
            }),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDynamicScheduleCard({
    required BuildContext context,
    required TimetableItem item,
    bool isCompleted = false,
    bool isCurrent = false,
  }) {
    final accentBorderColor = AppColors.getSubjectAccentColor(
      item.subjectCode,
      isBreak: item.isBreak,
    );

    if (item.isBreak) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentBorderColor, width: 6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        item.timeRange,
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
        ),
      );
    }

    return InkWell(
      onTap: () => !item.isBreak ? SubjectDetailPage.navigate(context, item) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color:
              isCurrent
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isCurrent
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.2),
            width: isCurrent ? 2.0 : 1.0,
          ),
          boxShadow:
              isCurrent
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentBorderColor, width: 6),
              ),
            ),
            child: Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : isCurrent
                          ? Icons.play_circle_filled_rounded
                          : Icons.schedule_rounded,
                      color:
                          isCompleted
                              ? AppColors.onSurfaceVariant
                              : isCurrent
                              ? AppColors.primary
                              : accentBorderColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTypography.textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isCurrent
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.timeRange,
                              style: AppTypography.textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight:
                                        isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isCurrent
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.room} • ${item.instructor}',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (item.category.isNotEmpty &&
                            item.category != 'Lecture') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.category.toUpperCase(),
                              style: AppTypography.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDayStr(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  String _getDayLabel(String code) {
    switch (code.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        return 'Monday';
    }
  }
}
