import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ExamTimeTablesScreen extends ConsumerWidget {
  const ExamTimeTablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Exam TimeTables',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('exams')
            .stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3525CD), Color(0xFF6F3DD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          LucideIcons.calendarClock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Examination Schedules',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Official schedules published for your enrolled course by Controller of Examinations.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                if (docs.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.calendarClock,
                            size: 56,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Exam Timetable Published Yet',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Examination papers, dates, and times will appear here as soon as they are published.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Scheduled Papers (${docs.length})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...docs.map((data) {
                    final colorHex =
                        data['colorHex'] as String? ?? '0xFF3525CD';
                    final color = Color(int.tryParse(colorHex) ?? 0xFF3525CD);

                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: color, width: 6.w),
                            ),
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      data['code'] as String? ??
                                          data['subjectId'] as String? ??
                                          'EXAM',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      data['status'] as String? ?? 'Scheduled',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                data['subject'] as String? ??
                                    data['name'] as String? ??
                                    'Examination',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                data['type'] as String? ?? 'Theory Examination',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: Divider(height: 1.h),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.calendar,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            data['day'] != null
                                                ? '${data['date'] ?? ''} (${data['day']})'
                                                : '${data['date'] ?? 'Upcoming'}',
                                            style: AppTypography.bodySmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        data['time'] as String? ??
                                            (data['startTime'] != null &&
                                                    data['endTime'] != null
                                                ? '${data['startTime']} - ${data['endTime']}'
                                                : '09:30 AM - 12:30 PM'),
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
