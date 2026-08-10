import '../models/timetable_item.dart';
import '../models/custom_timetable_membership.dart';

abstract class TimetableRepository {
  Future<List<TimetableItem>> getWeeklySchedule(String classCode);
  Future<List<TimetableItem>> getDailySchedule(
    String classCode,
    String dayOfWeek,
  );
  Future<TimetableItem?> getOngoingItem(String classCode);
  Future<TimetableItem?> getNextItem(String classCode);
  
  // Custom Timetables
  Future<List<CustomTimetableMembership>> getJoinedCustomTimetables();
  Future<void> leaveCustomTimetable(String timetableId);
}
