import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/curriculum_item.dart';

class SubjectDetailsScreen extends StatelessWidget {
  final CurriculumItem subject;

  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Subject Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    subject.subjectCode,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            
            // Title
            Text(
              subject.subjectName,
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                height: 1.2.h,
              ),
            ),
            SizedBox(height: 8.h),
            
            // Subtitle (Mocked Prof / Fall)
            Text(
              'Prof. Sarah Jenkins • Fall 2024',
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 32.h),
            
            // 4 Grid Items
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.35,
              children: [
                _buildInfoCard(Icons.school_outlined, 'COURSE TYPE', subject.type),
                _buildInfoCard(Icons.star_outline_rounded, 'CREDITS', subject.credits.toString().replaceAll('.0', '')),
                _buildInfoCard(Icons.calendar_today_outlined, 'SEMESTER', subject.semester.toString()),
                _buildInfoCard(Icons.category_outlined, 'CATEGORY', subject.category),
              ],
            ),
            SizedBox(height: 32.h),
            
            // Prerequisites
            _buildSectionCard(
              icon: Icons.account_tree_outlined,
              title: 'Prerequisites',
              content: subject.prerequisites,
              iconColor: AppColors.primary,
            ),
            SizedBox(height: 24.h),
            
            // Description
            _buildSectionCard(
              icon: Icons.info_outline_rounded,
              title: 'Description',
              content: subject.description,
              iconColor: AppColors.primary,
            ),
            SizedBox(height: 24.h),
            
            // Resources Section
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0.w),
                    child: Text(
                      'Resources',
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(height: 1.h, indent: 16, endIndent: 16),
                  _buildResourceTile(Icons.description_outlined, 'Course Materials'),
                  Divider(height: 1.h, indent: 16, endIndent: 16),
                  _buildResourceTile(Icons.edit_note_outlined, 'Assignments'),
                  Divider(height: 1.h, indent: 16, endIndent: 16),
                  _buildResourceTile(Icons.library_books_outlined, 'Notes'),
                ],
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required String content, required Color iconColor}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Icon(icon, color: iconColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTile(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {}, // Future implementation
    );
  }
}
