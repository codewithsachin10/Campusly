import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClassChangeAlertScreen extends ConsumerWidget {
  final String payload; // JSON encoded string from FCM

  const ClassChangeAlertScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(payload);
    } catch (e) {
      debugPrint("Failed to decode payload: $e");
    }

    final changeType = data['change_type'] ?? 'UPDATE';
    final oldData = data['old_data'] != null ? data['old_data'] as Map<String, dynamic> : null;
    final newData = data['new_data'] != null ? data['new_data'] as Map<String, dynamic> : null;
    final subject = newData?['subject'] ?? oldData?['subject'] ?? 'Unknown Subject';

    IconData icon;
    Color color;
    String title;
    
    switch (changeType) {
      case 'VENUE_CHANGED':
        icon = LucideIcons.mapPin;
        color = Colors.orange;
        title = "Venue Changed";
        break;
      case 'TIME_CHANGED':
        icon = LucideIcons.clock;
        color = Colors.blue;
        title = "Time Changed";
        break;
      case 'CANCELLED':
        icon = LucideIcons.xOctagon;
        color = Colors.red;
        title = "Class Cancelled";
        break;
      case 'FACULTY_CHANGED':
        icon = LucideIcons.userCheck;
        color = Colors.purple;
        title = "Faculty Changed";
        break;
      default:
        icon = LucideIcons.info;
        color = Colors.grey;
        title = "Class Update";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Class Alert'),
        leading: IconButton(
          icon: Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: color),
                ),
                SizedBox(height: 24.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 40.h),
                
                if (changeType == 'VENUE_CHANGED') _buildChangeRow(LucideIcons.doorOpen, "Old Venue", oldData?['room'] ?? '-', "New Venue", newData?['room'] ?? '-'),
                if (changeType == 'TIME_CHANGED') _buildChangeRow(LucideIcons.clock, "Old Time", "${oldData?['start_time']} - ${oldData?['end_time']}", "New Time", "${newData?['start_time']} - ${newData?['end_time']}"),
                if (changeType == 'FACULTY_CHANGED') _buildChangeRow(LucideIcons.user, "Old Faculty", oldData?['faculty'] ?? '-', "New Faculty", newData?['faculty'] ?? '-'),
                if (changeType == 'CANCELLED') 
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, color: Colors.red),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "This class has been cancelled. Enjoy your free time!",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: FilledButton(
                    onPressed: () {
                      context.pop();
                      // Optionally, trigger a refresh of the timetable here
                    },
                    child: Text('Acknowledge', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChangeRow(IconData icon, String oldLabel, String oldValue, String newLabel, String newValue) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(oldLabel, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    Text(oldValue, style: TextStyle(fontSize: 16.sp, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                SizedBox(width: 6.w),
                Icon(LucideIcons.arrowDown, size: 16, color: Colors.blue),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(newLabel, style: TextStyle(fontSize: 12.sp, color: Colors.blue)),
                    Text(newValue, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
