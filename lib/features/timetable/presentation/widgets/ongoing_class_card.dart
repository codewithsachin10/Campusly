import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';

/// Isolated ongoing class card that ticks independently with [liveTickerProvider]
/// to prevent full dashboard re-renders every second.
class OngoingClassCard extends ConsumerWidget {
  const OngoingClassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingAsync = ref.watch(ongoingClassProvider);

    return ongoingAsync.when(
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: const CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (ongoing) {
        if (ongoing == null) return const SizedBox.shrink();

        final now = DateTime.now();
        final currentMin = now.hour * 60 + now.minute;
        final endMin = ongoing.endHour * 60 + ongoing.endMinute;
        final minsLeft = (endMin - currentMin).clamp(0, 999);

        final startMin = ongoing.startHour * 60 + ongoing.startMinute;
        final totalDur = endMin - startMin;
        final elapsed = currentMin - startMin;
        final progress = totalDur > 0
            ? (elapsed / totalDur * 100).clamp(0.0, 100.0)
            : 0.0;

        final badgeColor = ongoing.isBreak
            ? const Color(0xFF26A69A)
            : AppColors.coral;
        final accentBorderColor = AppColors.getSubjectAccentColor(
          ongoing.subjectCode,
          isBreak: ongoing.isBreak,
        );

        return PressableScale(
          onTap: () => !ongoing.isBreak
              ? SubjectDetailPage.navigate(context, ongoing)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: AppShadows.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: accentBorderColor,
                      width: 6.w,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                ongoing.isBreak
                                    ? 'ONGOING BREAK'
                                    : 'ONGOING CLASS',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      ongoing.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        height: 1.3.h,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: badgeColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          ongoing.timeRange,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: badgeColor,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            ongoing.room,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ongoing.isBreak
                              ? 'Break Progress'
                              : 'Course Progress',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${progress.toInt()}%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999.r),
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
    );
  }
}
