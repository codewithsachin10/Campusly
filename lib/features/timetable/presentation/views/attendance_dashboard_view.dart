import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/attendance_details_sheet.dart';

class AttendanceDashboardView extends ConsumerWidget {
  const AttendanceDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);

    if (user == null) {
      return const Center(child: Text('Please sign in to view attendance.'));
    }

    if (currentClass == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.graduationCap, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'No Class Joined',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Join or search for an academic section to start tracking your attendance.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final asyncSchedule = ref.watch(weeklyScheduleProvider);

    return asyncSchedule.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading schedule: $err')),
      data: (items) {
        // Filter out breaks and map to distinct subject code/title pairs
        final subjects = <String, String>{};
        for (final item in items) {
          if (!item.isBreak) {
            final code = (item.subjectCode != null && item.subjectCode!.isNotEmpty)
                ? item.subjectCode!
                : item.title;
            subjects[code] = item.title;
          }
        }

        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.calendarDays, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'No Classes Scheduled',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This section has no active classes in the timetable yet.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return _AttendanceListContent(
          userId: user.id,
          subjects: subjects,
        );
      },
    );
  }
}

class _AttendanceListContent extends ConsumerWidget {
  final String userId;
  final Map<String, String> subjects;

  const _AttendanceListContent({
    required this.userId,
    required this.subjects,
  });

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Hub',
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Overall Summary Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
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
                      const SizedBox(height: 8),
                      Text(
                        totalClasses > 0 ? '${overallPercentage.toStringAsFixed(1)}%' : '0.0%',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalClasses > 0
                            ? '$totalPresent Present out of $totalClasses classes'
                            : 'Mark your classes below to track progress',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
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
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: totalClasses > 0 ? (overallPercentage / 100).clamp(0.0, 1.0) : 0.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Icon(LucideIcons.award, color: Colors.white, size: 36),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'SUBJECT-BY-SUBJECT BREAKDOWN',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // List of subject cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        ],
      ),
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          AttendanceDetailsSheet.show(
            context,
            subjectCode: subjectCode,
            subjectName: subjectName,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: asyncAtt.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (att) {
              final pct = att.totalCount > 0 ? (att.presentCount / att.totalCount) * 100 : 0.0;
              final isUnderTarget = pct < 75.0;

              // Calculate Bunk Predictor Text
              String bunkStatus = "";
              Color bunkBadgeColor = Colors.grey;
              if (att.totalCount == 0) {
                bunkStatus = "No classes logged yet";
                bunkBadgeColor = Colors.grey.shade600;
              } else {
                if (pct >= 75.0) {
                  // Calculate how many we can miss
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
                    bunkStatus = "Safe to miss next $safeBunks class${safeBunks > 1 ? 'es' : ''}!";
                    bunkBadgeColor = AppColors.success;
                  } else {
                    bunkStatus = "⚠️ Cannot miss today's class!";
                    bunkBadgeColor = AppColors.warning;
                  }
                } else {
                  // Calculate how many to attend
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
                  bunkStatus = "Must attend next $requiredAttends class${requiredAttends > 1 ? 'es' : ''} to reach 75%";
                  bunkBadgeColor = AppColors.error;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.getSubjectAccentColor(subjectCode).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                subjectCode,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.getSubjectAccentColor(subjectCode),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subjectName,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            att.totalCount > 0 ? '${pct.toStringAsFixed(1)}%' : '0.0%',
                            style: AppTypography.headlineMedium.copyWith(
                              color: isUnderTarget ? AppColors.error : AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${att.presentCount}/${att.totalCount} classes',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: bunkBadgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pct >= 75.0 ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                          color: bunkBadgeColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bunkStatus,
                            style: AppTypography.labelSmall.copyWith(
                              color: bunkBadgeColor,
                              fontWeight: FontWeight.bold,
                            ),
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
