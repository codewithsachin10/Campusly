import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';

/// Isolated next-class card that ticks independently with [liveTickerProvider]
/// to prevent full dashboard re-renders every second.
class NextClassCard extends ConsumerWidget {
  final bool hasTodayItems;

  const NextClassCard({super.key, this.hasTodayItems = false});

  static String _getDayStr(int weekday) {
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

  static String _getDayLabel(String code) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextAsync = ref.watch(nextClassProvider);
    final ongoing = ref.watch(ongoingClassProvider).value;

    return nextAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (next) {
        if (next == null) {
          if (ongoing == null && hasTodayItems) {
            // All classes completed for today
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.h,
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
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALL CLASSES COMPLETED TODAY! 🌟',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Great job! Have a restful evening.',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
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

        // Fine-grained live countdown tick: only this card updates each second
        ref.watch(liveTickerProvider);

        final now = DateTime.now();
        final currentSecs = now.hour * 3600 + now.minute * 60 + now.second;
        final startSecs = next.startHour * 3600 + next.startMinute * 60;
        final isToday = next.dayOfWeek.toLowerCase() == _getDayStr(now.weekday);
        final diffSecs = startSecs - currentSecs;

        String timerOrDateDisplay;
        if (isToday && diffSecs > 0) {
          final h = (diffSecs ~/ 3600).toString().padLeft(2, '0');
          final m = ((diffSecs % 3600) ~/ 60).toString().padLeft(2, '0');
          final s = (diffSecs % 60).toString().padLeft(2, '0');
          timerOrDateDisplay = '$h:$m:$s';
        } else {
          timerOrDateDisplay =
              '${_getDayLabel(next.dayOfWeek).toUpperCase()} • ${next.startTime}';
        }

        return PressableScale(
          onTap: () => !next.isBreak
              ? SubjectDetailPage.navigate(context, next)
              : null,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
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
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday && diffSecs > 0
                            ? 'NEXT CLASS IN'
                            : 'UPCOMING CLASS ON',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        timerOrDateDisplay,
                        style: AppTypography.textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: (isToday && diffSecs > 0) ? 20.sp : 15.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Upcoming',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      next.shortTitle,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
