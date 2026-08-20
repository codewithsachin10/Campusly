import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/campus_location.dart';

class LocationBottomSheet extends StatelessWidget {
  final CampusLocation location;
  final VoidCallback onGetDirections;

  const LocationBottomSheet({
    super.key,
    required this.location,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    location.category,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (location.description != null) ...[
              SizedBox(height: 8.h),
              Text(
                location.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
              ),
            ],
            SizedBox(height: 16.h),

            SizedBox(height: 24.h),
            if (location.rooms != null && location.rooms!.isNotEmpty) ...[
              Text(
                'Rooms',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: location.rooms!.map((room) {
                  return Chip(
                    label: Text(room),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGetDirections,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Get Directions',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
