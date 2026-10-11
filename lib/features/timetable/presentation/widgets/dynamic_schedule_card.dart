import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_colors.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';

/// Editorial timeline row replacing nested cards.
/// Displays tabular time on left with vertical connector, and class block on right.
/// When [isCurrent] is true, watches [liveTickerProvider] to dynamically display
/// live beacon, "Ends in X mins", and course progress in real-time.
class DynamicScheduleCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = SubjectColors.forSubject(item.subjectCode, isDark: isDark);
    final contentOpacity = isCompleted ? 0.5 : 1.0;

    int minsLeft = 0;
    int elapsed = 0;
    int totalDur = 0;
    double progress = 0.0;

    if (isCurrent) {
      // Re-evaluate countdown and progress when live ticker updates
      ref.watch(liveTickerProvider);
      final now = DateTime.now();
      final currentMin = now.hour * 60 + now.minute;
      final startMin = item.startHour * 60 + item.startMinute;
      final endMin = item.endHour * 60 + item.endMinute;
      totalDur = (endMin - startMin).clamp(1, 1440);
      elapsed = (currentMin - startMin).clamp(0, totalDur);
      minsLeft = (endMin - currentMin).clamp(0, 999);
      progress = (elapsed / totalDur).clamp(0.0, 1.0);
    }

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
                  ? _buildBreakBlock(
                      context,
                      isDark,
                      isCurrent: isCurrent,
                      minsLeft: minsLeft,
                      elapsed: elapsed,
                      totalDur: totalDur,
                      progress: progress,
                    )
                  : _buildClassBlock(
                      context,
                      isDark,
                      subjectColor,
                      isCurrent: isCurrent,
                      minsLeft: minsLeft,
                      elapsed: elapsed,
                      totalDur: totalDur,
                      progress: progress,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakBlock(
    BuildContext context,
    bool isDark, {
    required bool isCurrent,
    required int minsLeft,
    required int elapsed,
    required int totalDur,
    required double progress,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF26A69A).withValues(alpha: 0.08)
            : (isDark
                ? AppColors.darkSurfaceContainer.withValues(alpha: 0.35)
                : AppColors.surfaceContainerLow.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14.r),
        border: isCurrent
            ? Border.all(
                color: const Color(0xFF26A69A),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.coffee,
                size: 16,
                color: isCurrent
                    ? const Color(0xFF26A69A)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? (isDark ? Colors.white : AppColors.onSurface)
                        : AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrent) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    minsLeft <= 0 ? 'Ending now' : '$minsLeft mins left',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF26A69A),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  item.timeRange,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          if (isCurrent && totalDur > 0) ...[
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(999.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? AppColors.darkSurfaceContainerHighest
                    : AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF26A69A),
                ),
                minHeight: 3.h,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassBlock(
    BuildContext context,
    bool isDark,
    Color subjectColor, {
    required bool isCurrent,
    required int minsLeft,
    required int elapsed,
    required int totalDur,
    required double progress,
  }) {
    final theme = Theme.of(context);
    final isUrgent = minsLeft <= 5;

    return PressableScale(
      onTap: () => SubjectDetailPage.navigate(context, item),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isCurrent
              ? (isDark
                  ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
                  : AppColors.coral.withValues(alpha: 0.05))
              : (isDark
                  ? AppColors.darkSurfaceContainer.withValues(alpha: 0.45)
                  : AppColors.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(16.r),
          border: isCurrent
              ? Border.all(
                  color: isUrgent ? AppColors.coral : AppColors.coral.withValues(alpha: 0.8),
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
                    blurRadius: 14,
                    offset: const Offset(0, 4),
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
                      // Header: Title & Badges
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
                          if (isCurrent) ...[
                            // Glowing LIVE NOW pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5.r,
                                    height: 5.r,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6.w),
                            // Countdown pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? AppColors.coral.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.darkSurface
                                        : AppColors.surfaceContainerLow),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: isUrgent
                                      ? AppColors.coral.withValues(alpha: 0.5)
                                      : (isDark
                                          ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
                                          : AppColors.outlineVariant.withValues(alpha: 0.3)),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUrgent
                                        ? LucideIcons.hourglass
                                        : LucideIcons.timer,
                                    size: 10,
                                    color: isUrgent
                                        ? AppColors.coral
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    minsLeft <= 0
                                        ? 'Ending now'
                                        : minsLeft == 1
                                            ? '1m left'
                                            : '$minsLeft mins left',
                                    style: TextStyle(
                                      color: isUrgent
                                          ? AppColors.coral
                                          : AppColors.onSurface,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (item.category.isNotEmpty &&
                              item.category != 'Lecture') ...[
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

                      // Progress indicator for current ongoing class
                      if (isCurrent && totalDur > 0) ...[
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$elapsed of $totalDur mins passed',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.coral,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceContainerHighest
                                : AppColors.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.coral,
                            ),
                            minHeight: 4.h,
                          ),
                        ),
                      ],
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
