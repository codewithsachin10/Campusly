import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/curriculum_provider.dart';
import '../../domain/models/curriculum_item.dart';
import 'subject_details_screen.dart';

class CurriculumScreen extends ConsumerWidget {
  const CurriculumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSemester = ref.watch(selectedSemesterProvider);
    final curriculumAsync = ref.watch(curriculumProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Curriculum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: curriculumAsync.when(
        data: (curriculumData) {
          if (curriculumData == null || curriculumData.subjects.isEmpty) {
            return _buildEmptyState(context, ref, selectedSemester);
          }

          final subjects = curriculumData.subjects;
          final coreCourses = subjects.where((s) => s.isTheory).toList();
          final laboratoryCourses = subjects.where((s) => s.isLab).toList();

          double totalCredits = subjects.fold(0.0, (sum, item) => sum + item.credits);
          
          // Mocks for UI visualization based on screenshot
          int totalRequiredCredits = 24; 
          double progress = (totalCredits / totalRequiredCredits).clamp(0.0, 1.0);

          return CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      Text(
                        curriculumData.departmentName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                          height: 1.2.h,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${curriculumData.batchName} • Semester ${curriculumData.currentSemester}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'CURRENTLY STUDYING SEMESTER ${curriculumData.currentSemester}'.toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      
                      // Gradient Card
                      _buildGradientCard(
                        semester: selectedSemester,
                        earnedCredits: totalCredits,
                        totalCredits: totalRequiredCredits,
                        coursesCount: subjects.length,
                        theoryCount: coreCourses.length,
                        labsCount: laboratoryCourses.length,
                        progress: progress,
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Semester Pills
                      _buildSemesterPills(context, ref, selectedSemester),
                      
                      SizedBox(height: 24.h),
                      
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard(totalCredits.toString().replaceAll('.0', ''), 'Credits', Colors.blue.shade700),
                          _buildStatCard(subjects.length.toString(), 'Courses', Colors.blue.shade700),
                          _buildStatCard(coreCourses.length.toString(), 'Theory', Colors.blue.shade700),
                          _buildStatCard(laboratoryCourses.length.toString(), 'Labs', Colors.blue.shade700),
                        ],
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Subjects Header & Search
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subjects',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primary),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      
                      // Search Bar
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: AppColors.onSurfaceVariant),
                            hintText: 'Search subjects...',
                            hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),

              // CORE COURSES SECTION
              if (coreCourses.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                    child: Text(
                      'CORE COURSES',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                      child: _buildSubjectCard(context, coreCourses[index]),
                    ),
                    childCount: coreCourses.length,
                  ),
                ),
              ],
              
              // LABORATORY SECTION
              if (laboratoryCourses.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: 24.0.w, right: 24.0.w, top: 24.0.h, bottom: 8.0.h),
                    child: Text(
                      'LABORATORY',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                      child: _buildSubjectCard(context, laboratoryCourses[index]),
                    ),
                    childCount: laboratoryCourses.length,
                  ),
                ),
              ],
              
              SliverToBoxAdapter(child: SizedBox(height: 48.h)),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.0.w),
            child: Text(
              'Failed to load curriculum:\n$e',
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, int selectedSemester) {
    return Padding(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            'My Curriculum',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'View your subjects and credits for the selected semester.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),
          _buildSemesterPills(context, ref, selectedSemester),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_rounded, size: 64, color: AppColors.outlineVariant),
                  SizedBox(height: 16.h),
                  Text(
                    'No curriculum data found for Semester $selectedSemester',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard({
    required int semester,
    required double earnedCredits,
    required int totalCredits,
    required int coursesCount,
    required int theoryCount,
    required int labsCount,
    required double progress,
  }) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [Color(0xFF3B28CC), Color(0xFF7442F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5A35E0).withValues(alpha: 0.4),
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
              Expanded(
                child: Text(
                  'Semester $semester',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: earnedCredits.toString().replaceAll('.0', ''),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalCredits',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '\nCREDITS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          Text(
            '$coursesCount Courses • $theoryCount Theory • $labsCount Labs',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 24.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}% Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterPills(BuildContext context, WidgetRef ref, int selectedSemester) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      child: Row(
        children: List.generate(8, (index) => index + 1).map((sem) {
          final isSelected = sem == selectedSemester;
          return GestureDetector(
            onTap: () => ref.read(selectedSemesterProvider.notifier).setSemester(sem),
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF5A35E0) : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.r),
                border: isSelected ? null : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    'S$sem',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 6.w),
                    Container(
                      width: 4.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color valueColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, CurriculumItem item) {
    final bool isLab = item.isLab;
    final Color tagBgColor = isLab 
        ? Colors.purple.withValues(alpha: 0.1) 
        : Colors.blue.withValues(alpha: 0.1);
    final Color tagTextColor = isLab 
        ? Colors.purple.shade700 
        : Colors.blue.shade700;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailsScreen(subject: item),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    item.subjectCode,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: tagTextColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.credits.toString().replaceAll('.0', ''),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                        color: tagTextColor,
                      ),
                    ),
                    Text(
                      'Credits',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              item.subjectName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                height: 1.2.h,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  isLab ? Icons.science_outlined : Icons.menu_book_outlined,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  item.type,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
