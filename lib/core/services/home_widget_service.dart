import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/timetable/domain/models/timetable_item.dart';

class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  static const String appGroupId = 'group.com.campusly.campusly';
  static const String androidWidgetName = 'CampuslyWidgetProvider';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error initializing HomeWidget group ID: $e');
    }
  }

  Future<void> updateWidgetData({
    TimetableItem? ongoingClass,
    TimetableItem? nextClass,
  }) async {
    try {
      if (ongoingClass != null && !ongoingClass.isBreak) {
        await HomeWidget.saveWidgetData('ongoing_title', ongoingClass.title);
        await HomeWidget.saveWidgetData('ongoing_room', '${ongoingClass.room} (${ongoingClass.timeRange})');
      } else {
        await HomeWidget.saveWidgetData('ongoing_title', 'No Ongoing Class');
        await HomeWidget.saveWidgetData('ongoing_room', 'Relax or review your notes ✨');
      }

      if (nextClass != null && !nextClass.isBreak) {
        await HomeWidget.saveWidgetData('next_title', nextClass.title);
        await HomeWidget.saveWidgetData('next_room', '${nextClass.room} • Starts at ${nextClass.startTime}');
      } else {
        await HomeWidget.saveWidgetData('next_title', 'No More Classes Today');
        await HomeWidget.saveWidgetData('next_room', 'Have a restful evening! 🌟');
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
      debugPrint('HomeWidget updated successfully.');
    } catch (e) {
      debugPrint('Error updating HomeWidget data: $e');
    }
  }
}
