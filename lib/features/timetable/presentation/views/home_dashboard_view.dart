import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/announcements_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/announcements_banner.dart';
import '../widgets/ongoing_class_card.dart';
import '../widgets/next_class_card.dart';
import '../widgets/dynamic_schedule_card.dart';
import '../../../../core/widgets/fade_slide_in.dart';
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
    final isAuthLoading = ref.watch(authControllerProvider.select((a) => a.isLoading));
    final isClassLoading = ref.watch(isCurrentClassLoadingProvider);
    final todayScheduleAsync = ref.watch(todayScheduleProvider);
    final joinedCustomTimetablesAsync = ref.watch(joinedCustomTimetablesProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentClass = ref.watch(currentClassProvider);

    ref.listen<AsyncValue<List<AnnouncementModel>>>(announcementsStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final latest = next.value!.first;
        if (latest.priority.toLowerCase() == 'high' && !_shownAlerts.contains(latest.id)) {
          _shownAlerts.add(latest.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _showUrgentNoticePopup(context, latest);
            }
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

    final isScheduleLoading =
        todayScheduleAsync.isLoading && !todayScheduleAsync.hasValue;
    final todayItems = todayScheduleAsync.value ?? [];
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final isWeekendOrEmpty = !isScheduleLoading && todayItems.isEmpty;
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
                        'Good morning, ${user?.name.trim().isNotEmpty == true ? user!.name.trim().split(' ').first : 'Student'} 👋',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 28.sp,
                          color: AppColors.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        headerDateText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            AnnouncementsBanner(),
            SizedBox(height: 16.h),

            if (isClassLoading || isAuthLoading) ...[
              _buildDashboardSkeleton(),
            ] else if (currentClass == null &&
                (joinedCustomTimetablesAsync.value == null ||
                    joinedCustomTimetablesAsync.value!.isEmpty)) ...[
              _buildNoTimetableState(context),
            ] else if (isScheduleLoading) ...[
              _buildDashboardSkeleton(),
            ] else ...[
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
                        isWeekend ? Icons.weekend_rounded : Icons.event_available_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      isWeekend ? 'Weekend Free Day! 🎉' : 'No Classes Today! 🎉',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      isWeekend
                          ? "It's the weekend! Relax, recharge, or catch up on self-paced projects."
                          : "You have no scheduled lectures for today. Enjoy your free time!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4.h,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
                   // Ongoing Class Card (Most Prominent)
            if (!isWeekendOrEmpty) ...[
              const OngoingClassCard(),
              SizedBox(height: 16.h),

              // Next Class Timer Box
              NextClassCard(hasTodayItems: todayItems.isNotEmpty),
            ],

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
                                  style: Theme.of(context).textTheme.headlineLarge
                                      ?.copyWith(
                                        fontSize: 28.sp,
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Classes',
                                  style: Theme.of(context).textTheme.labelMedium
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
                                  style: Theme.of(context).textTheme.headlineLarge
                                      ?.copyWith(
                                        fontSize: 28.sp,
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Free Periods',
                                  style: Theme.of(context).textTheme.labelMedium
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Tap Full Calendar to explore your weekly timetable.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...todayItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final currentMin = now.hour * 60 + now.minute;
                final startMin = item.startHour * 60 + item.startMinute;
                final endMin = item.endHour * 60 + item.endMinute;
                final isCompleted = currentMin >= endMin;
                final isCurrent = currentMin >= startMin && currentMin < endMin;

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.0.h),
                  child: FadeSlideIn(
                    index: index,
                    child: DynamicScheduleCard(
                      item: item,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                    ),
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

  Widget _buildDashboardSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 140.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 110.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  Container(
                    width: 70.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
              Container(
                width: 200.w,
                height: 22.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              Container(
                width: double.infinity,
                height: 8.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Container(
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        ...List.generate(
          2,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 12.0.h),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ),
      ],
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You haven\'t selected or joined any class timetable yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _showUrgentNoticePopup(BuildContext context, AnnouncementModel ann) {
    if (!context.mounted) return;

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
                  subjectName ?? '-',
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
                                oldVenue ?? '-',
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
                                          newVenue ?? '-',
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
