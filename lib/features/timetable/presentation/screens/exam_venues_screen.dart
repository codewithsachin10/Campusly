import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:intl/intl.dart';

final examVenuesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('exam_schedules')
      .select('*, exam_papers(*)')
      .eq('department_id', user.department ?? '')
      .eq('academic_year', user.year ?? '')
      .eq('semester', user.semester ?? 0)
      .eq('status', 'venues_published') // ONLY venues_published
      .order('created_at', ascending: false);

  List<Map<String, dynamic>> allVenues = [];

  for (var schedule in response) {
    final papers = schedule['exam_papers'] as List<dynamic>? ?? [];
    for (var paper in papers) {
      // Find venue for this user's section
      final venuesMap = paper['venues'] as Map<String, dynamic>? ?? {};
      final myVenue = venuesMap[user.section ?? ''];
      
      String room = myVenue != null && myVenue['room'] != null ? myVenue['room'] : 'Not Allocated';
      String seatNo = myVenue != null && myVenue['seatNo'] != null ? myVenue['seatNo'] : 'Not Allocated';

      allVenues.add({
        'schedule_name': schedule['schedule_name'],
        'exam_type': schedule['exam_type'],
        'subject': paper['subject'],
        'exam_date': paper['exam_date'],
        'start_time': paper['start_time'],
        'end_time': paper['end_time'],
        'room': room,
        'seatNo': seatNo,
      });
    }
  }

  // Sort by date ascending
  allVenues.sort((a, b) {
    if (a['exam_date'] == null) return 1;
    if (b['exam_date'] == null) return -1;
    return a['exam_date'].compareTo(b['exam_date']);
  });

  return allVenues;
});

class ExamVenuesScreen extends ConsumerWidget {
  const ExamVenuesScreen({super.key});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Upcoming';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final dt = DateTime(2000, 1, 1, hour, min);
        return DateFormat('h:mm a').format(dt);
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(examVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Venues'),
      ),
      body: venuesAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading venues: $err')),
        data: (venues) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0058BE), Color(0xFF0075FF)],
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
                          LucideIcons.building2,
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
                              'Your assigned halls and seat numbers for upcoming examinations.',
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

                if (venues.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.building,
                            size: 56,
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Venues Allocated Yet',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Seating arrangements are usually published 1-2 days prior to the examination date.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Allotted Venues (${venues.length})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...venues.map((data) {
                    final color = Color(0xFF0058BE);

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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['room'] as String? ?? 'Examination Hall',
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            data['schedule_name'] as String? ?? 'Exam',
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
                                "15m prior (${_formatTime(data['start_time'])})",
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
                                'Paper / Subject',
                                "${data['subject']} (${_formatDate(data['exam_date'])})",
                                AppColors.onSurface,
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
