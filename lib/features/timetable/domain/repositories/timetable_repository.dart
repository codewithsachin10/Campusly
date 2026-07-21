import '../models/timetable_item.dart';

abstract class TimetableRepository {
  Future<List<TimetableItem>> getWeeklySchedule(String classCode);
  Future<List<TimetableItem>> getDailySchedule(
    String classCode,
    String dayOfWeek,
  );
  Future<TimetableItem?> getOngoingItem(String classCode);
  Future<TimetableItem?> getNextItem(String classCode);
}
