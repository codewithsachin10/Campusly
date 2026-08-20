import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool venueChanges = true;
  bool timeChanges = true;
  bool cancellations = true;
  bool facultyChanges = true;
  bool generalUpdates = true;
  bool sound = true;
  bool vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Preferences'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Text(
              "Smart Class Alerts",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: Text('Venue Changes'),
            subtitle: Text('Notify when a class room is changed'),
            secondary: Icon(LucideIcons.mapPin),
            value: venueChanges,
            onChanged: (val) => setState(() => venueChanges = val),
          ),
          SwitchListTile(
            title: Text('Time Changes'),
            subtitle: Text('Notify when class timings are modified'),
            secondary: Icon(LucideIcons.clock),
            value: timeChanges,
            onChanged: (val) => setState(() => timeChanges = val),
          ),
          SwitchListTile(
            title: Text('Cancellations'),
            subtitle: Text('Notify when a class is cancelled'),
            secondary: Icon(LucideIcons.xOctagon),
            value: cancellations,
            onChanged: (val) => setState(() => cancellations = val),
          ),
          SwitchListTile(
            title: Text('Faculty Changes'),
            subtitle: Text('Notify when a different faculty is taking the class'),
            secondary: Icon(LucideIcons.userCheck),
            value: facultyChanges,
            onChanged: (val) => setState(() => facultyChanges = val),
          ),
          
          Divider(),
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Text(
              "General",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: Text('General Updates'),
            subtitle: Text('Announcements from the admin'),
            secondary: Icon(LucideIcons.bell),
            value: generalUpdates,
            onChanged: (val) => setState(() => generalUpdates = val),
          ),
          
          Divider(),
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Text(
              "Delivery",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: Text('Play Sound'),
            secondary: Icon(LucideIcons.volume2),
            value: sound,
            onChanged: (val) => setState(() => sound = val),
          ),
          SwitchListTile(
            title: Text('Vibration'),
            secondary: Icon(LucideIcons.vibrate),
            value: vibration,
            onChanged: (val) => setState(() => vibration = val),
          ),
        ],
      ),
    );
  }
}
