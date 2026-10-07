import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_colors.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/models/timetable_item.dart';
import '../screens/subject_detail_page.dart';

/// Editorial timeline row replacing the nested heavy cards.
/// Displays tabular time on left with vertical connector, and class block on right.
class DynamicScheduleCard extends StatelessWidget {
  final TimetableItem item;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;

  const DynamicScheduleCard({
    super.key,
    required this.item,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = SubjectColors.forSubject(item.subjectCode, isDark: isDark);
    final contentOpacity = isCompleted ? 0.5 : 1.0;

    return Opacity(
      opacity: contentOpacity,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Tabular Figures Time
            SizedBox(
              width: 58.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 2.h),
                  Text(
                    item.startTime,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontFamily: 'monospace',
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent
                          ? AppColors.coral
                          : (isCompleted
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item.endTime,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontFamily: 'monospace',
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            // Timeline Connector Track with Node Dot
            SizedBox(
              width: 18.w,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Vertical Hairline Connector
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 1.5.w,
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(alpha: 0.35)
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // Node Indicator Dot
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: isCurrent
                        ? const _PulsingNowDot()
                        : Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? (isDark
                                      ? AppColors.darkOutline
                                      : AppColors.outlineVariant)
                                  : (item.isBreak
                                      ? AppColors.onSurfaceVariant
                                      : subjectColor),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.background,
                                width: 2,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            // Right Column: Class Block
            Expanded(
              child: item.isBreak
                  ? _buildBreakBlock(context, isDark)
                  : _buildClassBlock(context, isDark, subjectColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakBlock(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.35)
            : AppColors.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.coffee,
            size: 16,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            item.timeRange,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassBlock(BuildContext context, bool isDark, Color subjectColor) {
    final theme = Theme.of(context);

    return PressableScale(
      onTap: () => SubjectDetailPage.navigate(context, item),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.coral.withValues(alpha: 0.05)
              : (isDark
                  ? AppColors.darkSurfaceContainer.withValues(alpha: 0.45)
                  : AppColors.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(16.r),
          border: isCurrent
              ? Border.all(
                  color: AppColors.coral,
                  width: 1.5,
                )
              : Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.2)
                      : AppColors.outlineVariant.withValues(alpha: 0.15),
                  width: 1.0,
                ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.coral.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored vertical subject bar
              Container(
                width: 4.5.w,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.coral : subjectColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                ),
              ),

              // Content Body
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Title & 'NOW' badge or Category chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                                color: isCurrent
                                    ? (isDark ? Colors.white : AppColors.onSurface)
                                    : AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (isCurrent)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            )
                          else if (item.category.isNotEmpty &&
                              item.category != 'Lecture')
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: SubjectColors.containerForSubject(
                                  item.subjectCode,
                                  isDark: isDark,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: TextStyle(
                                  color: SubjectColors.onContainerForSubject(
                                    item.subjectCode,
                                    isDark: isDark,
                                  ),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),

                      // Footer metadata: Room chip and Instructor name
                      Row(
                        children: [
                          if (item.room.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.mapPin,
                                    size: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    item.room,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          if (item.instructor.isNotEmpty) ...[
                            Icon(
                              LucideIcons.user,
                              size: 11,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                item.instructor,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing 'NOW' indicator dot for the active ongoing class timeline node.
class _PulsingNowDot extends StatefulWidget {
  const _PulsingNowDot();

  @override
  State<_PulsingNowDot> createState() => _PulsingNowDotState();
}

class _PulsingNowDotState extends State<_PulsingNowDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 14.r,
                height: 14.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.coral.withValues(
                    alpha: (0.8 - _controller.value * 0.5).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
            Container(
              width: 9.r,
              height: 9.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral,
              ),
            ),
          ],
        );
      },
    );
  }
}
