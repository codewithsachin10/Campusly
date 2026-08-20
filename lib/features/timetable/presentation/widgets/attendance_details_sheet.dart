import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';

class _TimelineEntry {
  final String dateString;
  final DateTime date;
  final String status;
  _TimelineEntry(this.dateString, this.date, this.status);
}

class AttendanceDetailsSheet extends ConsumerStatefulWidget {
  final String subjectCode;
  final String subjectName;

  const AttendanceDetailsSheet({
    super.key,
    required this.subjectCode,
    required this.subjectName,
  });

  static void show(
    BuildContext context, {
    required String subjectCode,
    required String subjectName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceDetailsSheet(
        subjectCode: subjectCode,
        subjectName: subjectName,
      ),
    );
  }

  @override
  ConsumerState<AttendanceDetailsSheet> createState() =>
      _AttendanceDetailsSheetState();
}

class _AttendanceDetailsSheetState
    extends ConsumerState<AttendanceDetailsSheet> {
  void _showEditCountsDialog(AttendanceModel current) {
    final presentCtrl = TextEditingController(
      text: current.presentCount.toString(),
    );
    final totalCtrl = TextEditingController(
      text: current.totalCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Edit Attendance Counts',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: presentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'No. of Classes Present',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Classes Held',
                border: OutlineInputBorder(),
              ),
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final present =
                  int.tryParse(presentCtrl.text) ?? current.presentCount;
              final total = int.tryParse(totalCtrl.text) ?? current.totalCount;
              final user = ref.read(authControllerProvider).value;
              if (user != null) {
                final key = AttendanceQueryKey(
                  userId: user.id,
                  subjectCode: widget.subjectCode,
                  subjectName: widget.subjectName,
                );
                ref
                    .read(attendanceProvider(key).notifier)
                    .updateCounts(present, total);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  int _dayOfWeekToInt(String day) {
    switch (day.trim().toLowerCase()) {
      case 'mon': return DateTime.monday;
      case 'tue': return DateTime.tuesday;
      case 'wed': return DateTime.wednesday;
      case 'thu': return DateTime.thursday;
      case 'fri': return DateTime.friday;
      case 'sat': return DateTime.saturday;
      case 'sun': return DateTime.sunday;
      default: return DateTime.monday;
    }
  }

  List<_TimelineEntry> _generateTimeline(AttendanceModel model, List<TimetableItem> schedule) {
    final subjectSchedule = schedule.where((item) => 
      !item.isBreak && 
      (item.subjectCode == widget.subjectCode || item.title == widget.subjectName)
    ).toList();
    
    if (subjectSchedule.isEmpty) {
      return model.history.map((log) {
        final date = DateTime.tryParse(log.dateString) ?? DateTime.now();
        return _TimelineEntry(log.dateString, date, log.status);
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    }

    final targetWeekdays = subjectSchedule.map((item) => _dayOfWeekToInt(item.dayOfWeek)).toSet();

    final List<_TimelineEntry> timeline = [];
    final today = DateTime.now();
    // Use Midnight today for cleaner math
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final startDate = todayMidnight.subtract(Duration(days: 30));
    final endDate = todayMidnight.add(Duration(days: 14));

    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      if (targetWeekdays.contains(currentDate.weekday)) {
        final dateString = currentDate.toIso8601String().split('T')[0];
        final existingLogs = model.history.where((log) => log.dateString == dateString).toList();
        final status = existingLogs.isNotEmpty ? existingLogs.first.status : 'not marked';
        timeline.add(_TimelineEntry(dateString, currentDate, status));
      }
    }

    // Add any explicitly logged dates that might fall outside this range or on non-scheduled days
    for (final log in model.history) {
      if (!timeline.any((entry) => entry.dateString == log.dateString)) {
         final date = DateTime.tryParse(log.dateString) ?? DateTime.now();
         timeline.add(_TimelineEntry(log.dateString, date, log.status));
      }
    }

    timeline.sort((a, b) => b.date.compareTo(a.date));
    return timeline;
  }

  void _showMarkAttendanceDialog(AttendanceModel current, String dateString) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Mark Attendance for $dateString',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.checkCircle, color: AppColors.success),
              title: Text('Present'),
              onTap: () {
                _markStatus(dateString, 'present');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.xCircle, color: AppColors.error),
              title: Text('Absent'),
              onTap: () {
                _markStatus(dateString, 'absent');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.slash, color: AppColors.warning),
              title: Text('Cancelled'),
              onTap: () {
                _markStatus(dateString, 'cancelled');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markStatus(String dateString, String status) {
    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      final key = AttendanceQueryKey(
        userId: user.id,
        subjectCode: widget.subjectCode,
        subjectName: widget.subjectName,
      );
      ref.read(attendanceProvider(key).notifier).markStatus(status, dateString: dateString);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return SizedBox.shrink();

    final key = AttendanceQueryKey(
      userId: user.id,
      subjectCode: widget.subjectCode,
      subjectName: widget.subjectName,
    );
    final asyncAttendance = ref.watch(attendanceProvider(key));
    final asyncSchedule = ref.watch(weeklyScheduleProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 16.h,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  LucideIcons.calendarCheck,
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
                      widget.subjectName,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Attendance & Smart Bunk Calculator',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              asyncAttendance.when(
                data: (model) => IconButton(
                  onPressed: () => _showEditCountsDialog(model),
                  icon: Icon(LucideIcons.edit3, color: AppColors.primary),
                  tooltip: 'Edit Counts',
                ),
                loading: () => SizedBox.shrink(),
                error: (_, _) => SizedBox.shrink(),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          Expanded(
            child: asyncAttendance.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (model) {
                final pct = model.percentage;
                final isRisk = model.willDropBelowIfMissedNext || pct < 75.0;
                final safeBunks = model.safeBunkClasses;

                final scheduleList = asyncSchedule.value ?? [];
                final timeline = _generateTimeline(model, scheduleList);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              label: 'Present',
                              value: '${model.presentCount}',
                              color: AppColors.success,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Total Classes',
                              value: '${model.totalCount}',
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Attendance %',
                              value: '${pct.toStringAsFixed(1)}%',
                              color: isRisk
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Smart Bunk Predictor Banner
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isRisk
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isRisk ? AppColors.error : AppColors.success,
                            width: 1.5.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRisk
                                  ? LucideIcons.alertTriangle
                                  : LucideIcons.shieldCheck,
                              color: isRisk
                                  ? AppColors.error
                                  : AppColors.success,
                              size: 28,
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRisk
                                        ? '⚠️ Attendance Alert'
                                        : '✅ Smart Bunk Predictor',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isRisk
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    isRisk
                                        ? "Warning: If you miss today's class, your attendance will drop below 75% REC criterion!"
                                        : "You can safely miss the next $safeBunks classes and stay above your 75% REC criterion.",
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Quick Log Section
                      Text(
                        'Log Today\'s Class Status',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              title: 'Present ✅',
                              color: AppColors.success,
                              onTap: () => ref
                                  .read(attendanceProvider(key).notifier)
                                  .markStatus('present'),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Absent ❌',
                              color: AppColors.error,
                              onTap: () => ref
                                  .read(attendanceProvider(key).notifier)
                                  .markStatus('absent'),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Cancelled 🚫',
                              color: AppColors.warning,
                              onTap: () => ref
                                  .read(attendanceProvider(key).notifier)
                                  .markStatus('cancelled'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // History Log
                      Text(
                        'Class Attendance History',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      if (timeline.isEmpty)
                        Container(
                          padding: EdgeInsets.all(24.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            'No dates marked or scheduled.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: timeline.length,
                          itemBuilder: (context, idx) {
                            final entry = timeline[idx];
                            final isP = entry.status == 'present';
                            final isA = entry.status == 'absent';
                            final isC = entry.status == 'cancelled';
                            
                            final nowStr = DateTime.now().toIso8601String().split('T')[0];
                            final isStrictlyFuture = entry.dateString.compareTo(nowStr) > 0;

                            return InkWell(
                              onTap: () {
                                if (isStrictlyFuture) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('You can only change attendance for today or past classes.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  _showMarkAttendanceDialog(model, entry.dateString);
                                }
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isStrictlyFuture ? AppColors.background.withValues(alpha: 0.5) : AppColors.background,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.dateString,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isStrictlyFuture ? AppColors.textSecondary : AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isP
                                                    ? AppColors.success
                                                    : isA
                                                    ? AppColors.error
                                                    : isC 
                                                    ? AppColors.warning
                                                    : Colors.grey)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        isP
                                            ? 'Present ✅'
                                            : isA
                                            ? 'Absent ❌'
                                            : isC
                                            ? 'Cancelled 🚫'
                                            : 'Not Marked ⏳',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isP
                                              ? AppColors.success
                                              : isA
                                              ? AppColors.error
                                              : isC
                                              ? AppColors.warning
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color),
        ),
        child: Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
