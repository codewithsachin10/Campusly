import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/announcements_provider.dart';
import '../providers/timetable_provider.dart';
import '../screens/subject_detail_page.dart';
import '../widgets/announcements_banner.dart';
import '../../../events/presentation/widgets/events_promo_banner.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../domain/models/announcement_model.dart';

final Set<String> _shownAlerts = {};

class HomeDashboardView extends ConsumerWidget {
  final VoidCallback onNavigateToSchedule;

  const HomeDashboardView({super.key, required this.onNavigateToSchedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final ongoingAsync = ref.watch(ongoingClassProvider);
    final nextAsync = ref.watch(nextClassProvider);
    final todayScheduleAsync = ref.watch(todayScheduleProvider);
    final joinedCustomTimetablesAsync = ref.watch(joinedCustomTimetablesProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentClass = ref.watch(currentClassProvider);
    ref.watch(liveTickerProvider);

    ref.listen<AsyncValue<List<AnnouncementModel>>>(announcementsStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final latest = next.value!.first;
        if (latest.priority.toLowerCase() == 'high' && !_shownAlerts.contains(latest.id)) {
          _shownAlerts.add(latest.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUrgentNoticePopup(context, latest);
          });
        }
      }
    });

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
        todayScheduleAsync.value == null || todayScheduleAsync.value!.isEmpty;
    final todayItems = todayScheduleAsync.value ?? [];
    final classCount = todayItems.where((i) => !i.isBreak).length;
    final breakCount = todayItems.where((i) => i.isBreak).length;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(todayScheduleProvider);
        ref.invalidate(dailyScheduleProvider);
        ref.invalidate(ongoingClassProvider);
        ref.invalidate(nextClassProvider);
        ref.invalidate(weeklyScheduleProvider);
        ref.invalidate(announcementsStreamProvider);
        ref.invalidate(notificationsStreamProvider);
        ref.invalidate(eventsStreamProvider);
        await Future.delayed(Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Row with Notification Bell
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, ${user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'Student'} 👋',
                        style: AppTypography.textTheme.headlineLarge?.copyWith(
                          fontSize: 28.sp,
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
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                InkWell(
                  onTap: () => context.push('/notifications'),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          LucideIcons.bell,
                          size: 24,
                          color: AppColors.onSurface,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            EventsPromoBanner(onTap: () => context.push('/events')),
            SizedBox(height: 16.h),
            _buildCampusPresenceBanner(context),
            SizedBox(height: 16.h),
            AnnouncementsBanner(),
            SizedBox(height: 16.h),

            if (currentClass == null && (joinedCustomTimetablesAsync.value == null || joinedCustomTimetablesAsync.value!.isEmpty))
              _buildNoTimetableState(context)
            else ...[
              // Weekend / No Classes Today Banner
              if (isWeekendOrEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64.w,
                      height: 64.h,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.weekend_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Classes Today! 🎉',
                      style: AppTypography.textTheme.headlineSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "It's a free day or the weekend! Relax, recharge, or catch up on self-paced projects.",
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4.h,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Ongoing Class Card (Most Prominent)
            if (!isWeekendOrEmpty) ...[
              ongoingAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stackTrace) => SizedBox.shrink(),
                data: (ongoing) {
                  if (ongoing == null) return SizedBox.shrink();

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
                      ? Color(0xFF26A69A)
                      : AppColors.primary;
                  final accentBorderColor = AppColors.getSubjectAccentColor(
                    ongoing.subjectCode,
                    isBreak: ongoing.isBreak,
                  );

                  return InkWell(
                    onTap: () => !ongoing.isBreak
                        ? SubjectDetailPage.navigate(context, ongoing)
                        : null,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          style: AppTypography
                                              .textTheme
                                              .labelMedium
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
                              SizedBox(height: 16.h),
                              Text(
                                ongoing.title,
                                style: AppTypography.textTheme.headlineSmall
                                    ?.copyWith(
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
                                    style: AppTypography.textTheme.bodyMedium
                                        ?.copyWith(
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
                                      style: AppTypography.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
              ),
              SizedBox(height: 16.h),

              // Next Class Timer Box
              nextAsync.when(
                loading: () => SizedBox.shrink(),
                error: (error, stackTrace) => SizedBox.shrink(),
                data: (next) {
                  final ongoing = ongoingAsync.value;
                  if (next == null) {
                    if (ongoing == null && todayItems.isNotEmpty) {
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
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
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
                                    style: AppTypography.textTheme.labelSmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                  ),
                                  SizedBox(height: 2.h),
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
                    return SizedBox.shrink();
                  }

                  // Compute countdown or display day
                  final currentSecs =
                      now.hour * 3600 + now.minute * 60 + now.second;
                  final startSecs =
                      next.startHour * 3600 + next.startMinute * 60;
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
                    onTap: () => !next.isBreak
                        ? SubjectDetailPage.navigate(context, next)
                        : null,
                    borderRadius: BorderRadius.circular(16.r),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Flexible(
                                child: Column(
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
                                    SizedBox(height: 2.h),
                                    Text(
                                      timerOrDateDisplay,
                                      style: AppTypography.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: (isToday && diffSecs > 0)
                                                ? 22
                                                : 16,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                                SizedBox(height: 2.h),
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
              SizedBox(height: 24.h),

              // Overview Section (2 Horizontal Cards)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$classCount',
                                  style: AppTypography.textTheme.headlineLarge
                                      ?.copyWith(
                                        fontSize: 28.sp,
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Classes',
                                  style: AppTypography.textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              Icons.coffee_rounded,
                              color: AppColors.secondary,
                              size: 26,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$breakCount',
                                  style: AppTypography.textTheme.headlineLarge
                                      ?.copyWith(
                                        fontSize: 28.sp,
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Free Periods',
                                  style: AppTypography.textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
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
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0.w,
                      vertical: 4.0.h,
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
                        Icon(
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
            SizedBox(height: 16.h),

            if (isWeekendOrEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: 48.h,
                  horizontal: 24.w,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24.r),
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
                    SizedBox(height: 16.h),
                    Text(
                      'No classes scheduled for today.',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
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
                  padding: EdgeInsets.only(bottom: 12.0.h),
                  child: _buildDynamicScheduleCard(
                    context: context,
                    item: item,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                  ),
                );
              }),
            ],
            ],
            SizedBox(height: 24.h),
          ],
        ),
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
                Icon(
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

    return InkWell(
      onTap: () =>
          !item.isBreak ? SubjectDetailPage.navigate(context, item) : null,
      borderRadius: BorderRadius.circular(16.r),
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
                    offset: Offset(0, 4),
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
                                style: AppTypography.textTheme.bodyLarge
                                    ?.copyWith(
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
                              style: AppTypography.textTheme.labelMedium
                                  ?.copyWith(
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
                              style: AppTypography.textTheme.labelSmall
                                  ?.copyWith(
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
  Widget _buildNoTimetableState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 48,
          ),
          SizedBox(height: 16.h),
          Text(
            'No timetable chosen',
            style: AppTypography.textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You haven\'t selected or joined any class timetable yet.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.push('/join-class-choice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Choose Timetable'),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusPresenceBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/campus-presence'),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade200.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.mapPin, color: Colors.blue),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Presence',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'See where your friends are and check-in!',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.blue.shade900),
          ],
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

  void _showUrgentNoticePopup(BuildContext context, AnnouncementModel ann) {
    String? subjectName;
    String? oldVenue;
    String? newVenue;

    // Attempt to parse standard format: "{subject} has moved from {old} to {new}."
    final RegExp venueChangeRegex = RegExp(r'^(.*?) has moved from (.*?) to (.*?)\.?$');
    final match = venueChangeRegex.firstMatch(ann.message);
    if (match != null) {
      subjectName = match.group(1);
      oldVenue = match.group(2);
      newVenue = match.group(3);
    }

    // Use fallback values if not parsed
    subjectName ??= ann.message;
    oldVenue ??= '-';
    newVenue ??= '-';

    final bool isVenueChange = ann.title.contains('Venue') || oldVenue != '-';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Top row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF4E5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.bellRing, color: Color(0xFFFF9500), size: 20),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'CLASS UPDATE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF9500),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  isVenueChange ? 'Class Venue Changed' : ann.title.replaceAll('🚨 ', ''),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle (Subject)
                Text(
                  subjectName!,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 12.h),

                // Time
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: Colors.grey.shade500),
                    SizedBox(width: 8.w),
                    Text(
                      'Today | 10:00 AM - 11:00 AM', // Displays current schedule time
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                if (isVenueChange) ...[
                  // Previous Venue
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.mapPin, size: 16, color: Colors.grey.shade700),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREVIOUS',
                                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              ),
                              Text(
                                oldVenue!,
                                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Down
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0.h),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(LucideIcons.arrowDown, size: 16, color: Colors.grey.shade400),
                      ),
                    ),
                  ),

                  // New Venue
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Color(0xFFFFD899)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4.w,
                            color: Color(0xFFFF9500),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(LucideIcons.mapPin, size: 16, color: Color(0xFFFF9500)),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'NEW VENUE',
                                          style: TextStyle(fontSize: 11.sp, color: Color(0xFFE57E00), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                        Text(
                                          newVenue!,
                                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],

                // Description Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    isVenueChange 
                        ? 'The classroom has been changed. Please proceed to the new venue.'
                        : ann.message,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                      height: 1.4.h,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B28CC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigateToSchedule();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF3B28CC),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'View Timetable',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                    ),
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
