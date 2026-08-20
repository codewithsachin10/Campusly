import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class TicketStatusBadge extends StatelessWidget {
  final String status;
  
  const TicketStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'in progress':
        dotColor = Colors.orange;
        bgColor = Color(0xFFFFF7E0); // Light yellow
        textColor = Color(0xFFB58000); // Darker yellow/orange
        break;
      case 'resolved':
      case 'closed':
        dotColor = Colors.green;
        bgColor = Color(0xFFE8F5E9); // Light green
        textColor = Color(0xFF2E7D32); // Dark green
        break;
      case 'open':
      default:
        dotColor = AppColors.primary;
        bgColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
