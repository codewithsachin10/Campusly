import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_colors.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';

/// Isolated ongoing class card that ticks independently with [liveTickerProvider]
/// to present a live, wonderful, real-time dashboard banner of the current class
/// and minutes remaining until it ends.
class OngoingClassCard extends ConsumerWidget {
  const OngoingClassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch liveTickerProvider to tick countdown & progress in real time
    ref.watch(liveTickerProvider);
    final ongoingAsync = ref.watch(ongoingClassProvider);

    return ongoingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (ongoing) {
        if (ongoing == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final now = DateTime.now();
        final currentMin = now.hour * 60 + now.minute;
        final startMin = ongoing.startHour * 60 + ongoing.startMinute;
        final endMin = ongoing.endHour * 60 + ongoing.endMinute;
        final totalDur = (endMin - startMin).clamp(1, 1440);
        final elapsed = (currentMin - startMin).clamp(0, totalDur);
        final minsLeft = (endMin - currentMin).clamp(0, 999);
        final progress = (elapsed / totalDur).clamp(0.0, 1.0);

        final subjectColor = SubjectColors.forSubject(
          ongoing.subjectCode,
          isDark: isDark,
        );
        final isUrgent = minsLeft <= 5;
        final badgeColor = ongoing.isBreak
            ? const Color(0xFF26A69A)
            : (isUrgent ? AppColors.coral : subjectColor);

        return PressableScale(
          onTap: () => !ongoing.isBreak
              ? SubjectDetailPage.navigate(context, ongoing)
              : null,
          child: Container(
            margin: EdgeInsets.only(bottom: 4.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkSurfaceContainer,
                        badgeColor.withValues(alpha: 0.12),
                      ]
                    : [
                        AppColors.surfaceContainerLowest,
                        badgeColor.withValues(alpha: 0.08),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isUrgent
                    ? AppColors.coral
                    : badgeColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUrgent
                      ? AppColors.coral.withValues(alpha: 0.22)
                      : badgeColor.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  // Accent color indicator on left edge
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 5.w,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          bottomLeft: Radius.circular(20.r),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 18.h, 18.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Status Bar: Radar Beacon + Live Countdown Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999.r),
                                  border: Border.all(
                                    color: badgeColor.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _LiveRadarBeacon(color: badgeColor),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        ongoing.isBreak
                                            ? 'BREAK IN PROGRESS'
                                            : 'CLASS IN PROGRESS',
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.sp,
                                          letterSpacing: 0.6,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            // Prominent Countdown Pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? AppColors.coral.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.darkSurface
                                        : AppColors.surfaceContainerLow),
                                borderRadius: BorderRadius.circular(999.r),
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
                                    size: 13,
                                    color: isUrgent
                                        ? AppColors.coral
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    minsLeft <= 0
                                        ? 'Ending now'
                                        : minsLeft == 1
                                            ? '1 min left'
                                            : '$minsLeft mins left',
                                    style: TextStyle(
                                      color: isUrgent
                                          ? AppColors.coral
                                          : AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 14.h),

                        // Title & Subject Code
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                ongoing.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                  fontSize: 19.sp,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ongoing.subjectCode != null &&
                                ongoing.subjectCode!.isNotEmpty &&
                                !ongoing.isBreak) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: SubjectColors.containerForSubject(
                                    ongoing.subjectCode!,
                                    isDark: isDark,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  ongoing.subjectCode!,
                                  style: TextStyle(
                                    color: SubjectColors.onContainerForSubject(
                                      ongoing.subjectCode!,
                                      isDark: isDark,
                                    ),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // Metadata Chips: Time, Room, Instructor
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 6.h,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 14,
                                  color: badgeColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  ongoing.timeRange,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                            if (ongoing.room.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.mapPin,
                                    size: 14,
                                    color: badgeColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    ongoing.room,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            if (ongoing.instructor.isNotEmpty && !ongoing.isBreak)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    ongoing.instructor,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Progress Bar Header & Value
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ongoing.isBreak
                                    ? '$elapsed of $totalDur mins break elapsed'
                                    : '$elapsed of $totalDur mins passed',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${(progress * 100).toInt()}% completed',
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 7.h),

                        // High-contrast smooth progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceContainerHighest
                                : AppColors.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                            minHeight: 8.h,
                          ),
                        ),

                        if (!ongoing.isBreak) ...[
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  'Tap to view details & syllabus',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                LucideIcons.arrowRight,
                                size: 12,
                                color: badgeColor,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing radar beacon with an expanding ripple ring and solid core.
class _LiveRadarBeacon extends StatefulWidget {
  final Color color;

  const _LiveRadarBeacon({required this.color});

  @override
  State<_LiveRadarBeacon> createState() => _LiveRadarBeaconState();
}

class _LiveRadarBeaconState extends State<_LiveRadarBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14.r,
      height: 14.r,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding radar wave
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 9.r,
                  height: 9.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                  ),
                ),
              ),
              // Core dot
              Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
