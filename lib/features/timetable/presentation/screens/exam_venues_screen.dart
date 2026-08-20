import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ExamVenuesScreen extends ConsumerWidget {
  const ExamVenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Exam Venues & Seating',
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
                      colors: [Color(0xFF0058BE), Color(0xFF2170E4)],
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
                          LucideIcons.mapPin,
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
                              'Seating Allocation',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Ensure you bring your physical ID Card and Hall Ticket to the examination hall.',
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
                            LucideIcons.mapPinOff,
                            size: 56,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Seating Venues Allotted Yet',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Hall numbers, seating arrangements, and reporting instructions will appear once assigned.',
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
                    'Allotted Venues (${docs.length})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...docs.map((data) {
                    final colorHex =
                        data['colorHex'] as String? ?? '0xFF0058BE';
                    final color = Color(int.tryParse(colorHex) ?? 0xFF0058BE);

                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(18.w),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Icon(
                                        LucideIcons.building,
                                        color: color,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['hall'] as String? ??
                                                data['room'] as String? ??
                                                'Examination Hall',
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.onSurface,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            data['block'] as String? ??
                                                (data['departmentId'] != null
                                                    ? '${data['departmentId']} Block'
                                                    : 'Academic Block'),
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: Divider(height: 1.h),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildVenueDetail(
                                LucideIcons.armchair,
                                'Seat Number',
                                data['seatNo'] as String? ?? 'Allotted at Hall',
                                color,
                              ),
                              _buildVenueDetail(
                                LucideIcons.clock,
                                'Reporting Time',
                                data['reportingTime'] as String? ??
                                    (data['startTime'] != null
                                        ? '15m prior (${data['startTime']})'
                                        : '09:00 AM'),
                                AppColors.onSurface,
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildVenueDetail(
                                LucideIcons.bookOpen,
                                'Papers',
                                data['subjects'] as String? ??
                                    data['name'] as String? ??
                                    'All Assigned Papers',
                                AppColors.onSurface,
                              ),
                              _buildVenueDetail(
                                LucideIcons.userCheck,
                                'Invigilators',
                                data['invigilator'] as String? ??
                                    'Assigned Staff',
                                AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildVenueDetail(
    IconData icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
