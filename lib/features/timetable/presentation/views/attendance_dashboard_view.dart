import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/attendance_details_sheet.dart';
import '../../../../core/theme/subject_colors.dart';
import '../widgets/more_bottom_sheet.dart';

class AttendanceDashboardView extends ConsumerWidget {
  const AttendanceDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);
    final joinedCustomTimetablesAsync = ref.watch(joinedCustomTimetablesProvider);

    if (user == null) {
      return Center(child: Text('Please sign in to view attendance.'));
    }

    if (currentClass == null && (joinedCustomTimetablesAsync.value == null || joinedCustomTimetablesAsync.value!.isEmpty)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.graduationCap,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                'No Class Joined',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Join or search for an academic section to start tracking your attendance.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),
              FilledButton.icon(
                onPressed: () => context.push('/join-class-choice'),
                icon: Icon(LucideIcons.search, size: 18),
                label: Text('Find a Class'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final asyncSchedule = ref.watch(weeklyScheduleProvider);

    return asyncSchedule.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error loading schedule: $err')),
      data: (items) {
        // Filter out breaks and map to distinct subject code/title pairs
        final subjects = <String, String>{};
        for (final item in items) {
          if (!item.isBreak) {
            final code =
                (item.subjectCode != null && item.subjectCode!.isNotEmpty)
                ? item.subjectCode!
                : item.title;
            subjects[code] = item.title;
          }
        }

        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.0.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.calendarDays,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Classes Scheduled',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This section has no active classes in the timetable yet.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _AttendanceListContent(userId: user.id, subjects: subjects);
      },
    );
  }
}

class _AttendanceListContent extends ConsumerWidget {
  final String userId;
  final Map<String, String> subjects;

  const _AttendanceListContent({required this.userId, required this.subjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collect all subject attendance states
    final attStates = <String, AsyncValue>{};
    for (final code in subjects.keys) {
      final key = AttendanceQueryKey(
        userId: userId,
        subjectCode: code,
        subjectName: subjects[code]!,
      );
      attStates[code] = ref.watch(attendanceProvider(key));
    }

    // Calculate overall statistics if all states are loaded
    double overallPercentage = 0.0;
    int totalPresent = 0;
    int totalClasses = 0;
    bool hasData = false;

    for (final state in attStates.values) {
      if (state.hasValue && state.value != null) {
        final val = state.value;
        totalPresent += val.presentCount as int;
        totalClasses += val.totalCount as int;
        hasData = true;
      }
    }

    if (hasData && totalClasses > 0) {
      overallPercentage = (totalPresent / totalClasses) * 100;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar.large(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          scrolledUnderElevation: 0,
          pinned: true,
          floating: false,
          leading: IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'More options',
            onPressed: () => MoreBottomSheet.show(context),
          ),
          title: Text(
            'Attendance',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(24.0.w),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Summary Card
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OVERALL ATTENDANCE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        totalClasses > 0
                            ? '${overallPercentage.toStringAsFixed(1)}%'
                            : '0.0%',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 42.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        totalClasses > 0
                            ? '$totalPresent Present out of $totalClasses classes'
                            : 'Mark your classes below to track progress',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          overallPercentage >= 85.0
                              ? '🏆 Excellent target completion!'
                              : overallPercentage >= 75.0
                              ? '🎉 On track (Above 75% REC criterion)'
                              : '⚠️ Below 75% REC criterion!',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90.w,
                      height: 90.h,
                      child: CircularProgressIndicator(
                        value: totalClasses > 0
                            ? (overallPercentage / 100).clamp(0.0, 1.0)
                            : 0.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(
                      LucideIcons.award,
                      color: Colors.white,
                      size: 36,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          Text(
            'SUBJECT-BY-SUBJECT BREAKDOWN',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),

          // Editorial list of subjects
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: subjects.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? AppColors.darkOutlineVariant.withValues(alpha: 0.6)
                    : AppColors.outlineVariant.withValues(alpha: 0.25),
              ),
              itemBuilder: (context, index) {
                final code = subjects.keys.elementAt(index);
                final name = subjects[code]!;

                return _SubjectAttendanceCard(
                  userId: userId,
                  subjectCode: code,
                  subjectName: name,
                );
              },
            ),
          ),
          SizedBox(height: 100.h),
        ],
      ),
    ),
  ),
],
);
  }
}

class _SubjectAttendanceCard extends ConsumerWidget {
  final String userId;
  final String subjectCode;
  final String subjectName;

  const _SubjectAttendanceCard({
    required this.userId,
    required this.subjectCode,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = AttendanceQueryKey(
      userId: userId,
      subjectCode: subjectCode,
      subjectName: subjectName,
    );
    final asyncAtt = ref.watch(attendanceProvider(key));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AttendanceDetailsSheet.show(
            context,
            subjectCode: subjectCode,
            subjectName: subjectName,
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: asyncAtt.when(
            loading: () => SizedBox(
              height: 52.h,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'Error: $err',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            data: (att) {
              final pct = att.totalCount > 0
                  ? (att.presentCount / att.totalCount) * 100
                  : 0.0;
              final isUnderTarget = pct < 75.0 && att.totalCount > 0;
              final subjectColor = SubjectColors.forSubject(subjectCode);

              // Calculate Bunk Predictor Text
              String bunkStatus = "";
              Color bunkBadgeColor = Colors.grey;
              if (att.totalCount == 0) {
                bunkStatus = "No classes logged yet";
                bunkBadgeColor = AppColors.textSecondary;
              } else {
                if (pct >= 75.0) {
                  int safeBunks = 0;
                  while (true) {
                    final nextTotal = att.totalCount + safeBunks + 1;
                    if ((att.presentCount / nextTotal) >= 0.75) {
                      safeBunks++;
                    } else {
                      break;
                    }
                  }
                  if (safeBunks > 0) {
                    bunkStatus =
                        "Safe to miss $safeBunks class${safeBunks > 1 ? 'es' : ''}";
                    bunkBadgeColor = AppColors.mint;
                  } else {
                    bunkStatus = "Cannot miss next class";
                    bunkBadgeColor = AppColors.warning;
                  }
                } else {
                  int requiredAttends = 0;
                  while (true) {
                    final nextPresent = att.presentCount + requiredAttends;
                    final nextTotal = att.totalCount + requiredAttends;
                    if ((nextPresent / nextTotal) < 0.75) {
                      requiredAttends++;
                    } else {
                      break;
                    }
                  }
                  bunkStatus =
                      "Attend next $requiredAttends to reach 75%";
                  bunkBadgeColor = AppColors.coral;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Subject color accent bar
                      Container(
                        width: 4.w,
                        height: 38.h,
                        decoration: BoxDecoration(
                          color: subjectColor,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Title & Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: subjectColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    subjectCode,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: subjectColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '${att.presentCount}/${att.totalCount} attended',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              subjectName,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Progress ring & percentage
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 42.w,
                            height: 42.h,
                            child: CircularProgressIndicator(
                              value: att.totalCount > 0
                                  ? (pct / 100).clamp(0.0, 1.0)
                                  : 0.0,
                              strokeWidth: 4,
                              backgroundColor: isDark
                                  ? AppColors.darkOutlineVariant
                                  : AppColors.outlineVariant.withValues(alpha: 0.3),
                              color: isUnderTarget
                                  ? AppColors.coral
                                  : (att.totalCount == 0
                                      ? AppColors.textSecondary
                                      : subjectColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            att.totalCount > 0 ? '${pct.toInt()}%' : '—',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11.sp,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  // Status chip
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: bunkBadgeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pct >= 75.0 || att.totalCount == 0
                              ? LucideIcons.checkCircle
                              : LucideIcons.alertTriangle,
                          color: bunkBadgeColor,
                          size: 13,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          bunkStatus,
                          style: AppTypography.labelSmall.copyWith(
                            color: bunkBadgeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
