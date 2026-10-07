import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class ActivityTimeline extends StatelessWidget {
  final String currentStatus;

  const ActivityTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'label': 'Created', 'status': 'Open'},
      {'label': 'In Review', 'status': 'In Review'},
      {'label': 'In Progress', 'status': 'In Progress'},
      {'label': 'Resolved', 'status': 'Resolved'},
    ];

    int currentIndex = 0;
    if (currentStatus == 'In Review') currentIndex = 1;
    if (currentStatus == 'In Progress') currentIndex = 2;
    if (currentStatus == 'Resolved' || currentStatus == 'Closed') currentIndex = 3;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background line
          Positioned(
            left: 20.w,
            right: 20.w,
            top: 10.h,
            child: Container(
              height: 2.h,
              color: AppColors.surfaceVariant,
            ),
          ),
          // Active line
          Positioned(
            left: 20.w,
            right: 20.w,
            top: 10.h,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: currentIndex == 0 ? 0.0 : (currentIndex / (stages.length - 1)),
              child: Container(
                height: 2.h,
                color: AppColors.primary,
              ),
            ),
          ),
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(stages.length, (index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isCurrent ? 24 : 20,
                    height: isCurrent ? 24 : 20,
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4.w)
                          : null,
                    ),
                    child: isCompleted && !isCurrent
                        ? Icon(Icons.check, size: 12, color: Colors.white)
                        : isCurrent
                            ? Center(
                                child: Container(
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                  ),
                  Text(
                    stages[index]['label']!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
