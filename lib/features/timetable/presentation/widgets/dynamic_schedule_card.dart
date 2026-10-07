import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/models/timetable_item.dart';
import '../screens/subject_detail_page.dart';

/// Reusable card displaying an individual timetable item / lecture / break.
class DynamicScheduleCard extends StatelessWidget {
  final TimetableItem item;
  final bool isCompleted;
  final bool isCurrent;

  const DynamicScheduleCard({
    super.key,
    required this.item,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentBorderColor = AppColors.getSubjectAccentColor(
      item.subjectCode,
      isBreak: item.isBreak,
    );

    if (item.isBreak) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.outlineVariant,
            style: BorderStyle.solid,
            width: 1.w,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentBorderColor, width: 6.w),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
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

    return PressableScale(
      onTap: () =>
          !item.isBreak ? SubjectDetailPage.navigate(context, item) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.2),
            width: isCurrent ? 2.0 : 1.0,
          ),
          boxShadow: isCurrent
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
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentBorderColor, width: 6.w),
              ),
            ),
            child: Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.0.h),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : isCurrent
                          ? Icons.play_circle_filled_rounded
                          : Icons.schedule_rounded,
                      color: isCompleted
                          ? AppColors.onSurfaceVariant
                          : isCurrent
                          ? AppColors.primary
                          : accentBorderColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16.w),
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
                                style: AppTypography.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              item.timeRange,
                              style: AppTypography.textTheme.labelMedium?.copyWith(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${item.room} • ${item.instructor}',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (item.category.isNotEmpty &&
                            item.category != 'Lecture') ...[
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              item.category.toUpperCase(),
                              style: AppTypography.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp,
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
}
