import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/attendance_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/attendance_details_sheet.dart';
import '../widgets/subject_notes_hub_sheet.dart';
import '../widgets/faculty_profile_sheet.dart';

class SubjectDetailPage extends ConsumerWidget {
  final TimetableItem item;

  const SubjectDetailPage({super.key, required this.item});

  static void navigate(BuildContext context, TimetableItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubjectDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final code = (item.subjectCode != null && item.subjectCode!.isNotEmpty)
        ? item.subjectCode!
        : item.title;
    final attKey = user != null
        ? AttendanceQueryKey(
            userId: user.id,
            subjectCode: code,
            subjectName: item.title,
          )
        : null;
    final notesKey = user != null
        ? NotesQueryKey(userId: user.id, subjectCode: code)
        : null;

    final asyncAtt = attKey != null
        ? ref.watch(attendanceProvider(attKey))
        : AsyncValue.data(null);
    final asyncNotes = notesKey != null
        ? ref.watch(notesProvider(notesKey))
        : AsyncValue.data(null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Subject Hub & Tools',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header Card
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
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            (item.subjectCode != null &&
                                    item.subjectCode!.isNotEmpty)
                                ? item.subjectCode!
                                : 'SUBJECT',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              item.room.isNotEmpty ? item.room : 'Room TBA',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    item.title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Divider(color: Colors.white24),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.instructor.isNotEmpty
                                        ? item.instructor
                                        : 'Faculty TBA',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Course Instructor',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      TextButton.icon(
                        onPressed: () {
                          FacultyProfileSheet.show(
                            context,
                            nameOrCode: item.instructor.isNotEmpty
                                ? item.instructor
                                : (item.subjectCode ?? ''),
                            fallbackName: item.instructor,
                          );
                        },
                        icon: Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          'Contact Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            Text(
              'Interactive Tools & Tracking',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            // 1. Attendance & Bunk Predictor Card
            InkWell(
              onTap: () => AttendanceDetailsSheet.show(
                context,
                subjectCode:
                    (item.subjectCode != null && item.subjectCode!.isNotEmpty)
                    ? item.subjectCode!
                    : item.title,
                subjectName: item.title,
              ),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
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
                                'Attendance Card',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tap to log present/absent & view bunk limits',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    asyncAtt.when(
                      loading: () => LinearProgressIndicator(),
                      error: (err, _) => Text(
                        'Error loading attendance',
                        style: AppTypography.bodySmall,
                      ),
                      data: (model) {
                        final p = model?.presentCount ?? 0;
                        final t = model?.totalCount ?? 0;
                        final pct = model?.percentage ?? 100.0;
                        final safe = model?.safeBunkClasses ?? 0;
                        final risk =
                            (model?.willDropBelowIfMissedNext ?? false) ||
                            pct < 75.0;

                        return Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$p / $t Classes Present',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      risk
                                          ? '⚠️ Warning: Risk < 75%!'
                                          : '✅ Safe to bunk: $safe',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: risk
                                            ? AppColors.error
                                            : AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (risk
                                              ? AppColors.error
                                              : AppColors.success)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '${pct.toStringAsFixed(1)}%',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: risk
                                        ? AppColors.error
                                        : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 2. Subject Notes Hub Card
            InkWell(
              onTap: () => SubjectNotesHubSheet.show(
                context,
                subjectCode:
                    (item.subjectCode != null && item.subjectCode!.isNotEmpty)
                    ? item.subjectCode!
                    : item.title,
                subjectName: item.title,
              ),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(
                            Icons.description_rounded,
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
                                'Notes Card',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tap to create, edit, or delete subject notes',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    asyncNotes.when(
                      loading: () => LinearProgressIndicator(),
                      error: (err, _) => Text(
                        'Error loading notes',
                        style: AppTypography.bodySmall,
                      ),
                      data: (notes) {
                        final count = notes?.length ?? 0;
                        final latest = count > 0
                            ? notes!.first.title
                            : 'No notes written yet. Tap to create one!';

                        return Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '$count Notes',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  latest,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
