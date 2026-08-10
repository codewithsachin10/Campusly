import 'package:flutter/material.dart';
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
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Smart Class Alerts",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: const Text('Venue Changes'),
            subtitle: const Text('Notify when a class room is changed'),
            secondary: const Icon(LucideIcons.mapPin),
            value: venueChanges,
            onChanged: (val) => setState(() => venueChanges = val),
          ),
          SwitchListTile(
            title: const Text('Time Changes'),
            subtitle: const Text('Notify when class timings are modified'),
            secondary: const Icon(LucideIcons.clock),
            value: timeChanges,
            onChanged: (val) => setState(() => timeChanges = val),
          ),
          SwitchListTile(
            title: const Text('Cancellations'),
            subtitle: const Text('Notify when a class is cancelled'),
            secondary: const Icon(LucideIcons.xOctagon),
            value: cancellations,
            onChanged: (val) => setState(() => cancellations = val),
          ),
          SwitchListTile(
            title: const Text('Faculty Changes'),
            subtitle: const Text('Notify when a different faculty is taking the class'),
            secondary: const Icon(LucideIcons.userCheck),
            value: facultyChanges,
            onChanged: (val) => setState(() => facultyChanges = val),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "General",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: const Text('General Updates'),
            subtitle: const Text('Announcements from the admin'),
            secondary: const Icon(LucideIcons.bell),
            value: generalUpdates,
            onChanged: (val) => setState(() => generalUpdates = val),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Delivery",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: const Text('Play Sound'),
            secondary: const Icon(LucideIcons.volume2),
            value: sound,
            onChanged: (val) => setState(() => sound = val),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            secondary: const Icon(LucideIcons.vibrate),
            value: vibration,
            onChanged: (val) => setState(() => vibration = val),
          ),
        ],
      ),
    );
  }
}
