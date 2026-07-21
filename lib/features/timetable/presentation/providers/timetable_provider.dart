import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../../data/repositories/firebase_timetable_repository.dart';
import '../../../../core/services/home_widget_service.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return FirebaseTimetableRepository();
});

// Currently selected day in Planner ('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun')
class SelectedDayNotifier extends Notifier<String> {
  @override
  String build() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  void select(String day) => state = day;
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, String>(() {
  return SelectedDayNotifier();
});

// Weekly full schedule for the currently joined class
final weeklyScheduleProvider = FutureProvider<List<TimetableItem>>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  if (currentClass == null) return [];
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getWeeklySchedule(currentClass.code);
});

// Daily schedule for strictly TODAY (`DateTime.now().weekday`)
final todayScheduleProvider = FutureProvider<List<TimetableItem>>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  if (currentClass == null) return [];
  final repository = ref.watch(timetableRepositoryProvider);
  final now = DateTime.now();
  String todayStr;
  switch (now.weekday) {
    case DateTime.monday:
      todayStr = 'mon';
      break;
    case DateTime.tuesday:
      todayStr = 'tue';
      break;
    case DateTime.wednesday:
      todayStr = 'wed';
      break;
    case DateTime.thursday:
      todayStr = 'thu';
      break;
    case DateTime.friday:
      todayStr = 'fri';
      break;
    case DateTime.saturday:
      todayStr = 'sat';
      break;
    case DateTime.sunday:
      todayStr = 'sun';
      break;
    default:
      todayStr = 'mon';
      break;
  }
  return repository.getDailySchedule(currentClass.code, todayStr);
});

// Daily schedule for the active day tab (`selectedDayProvider`)
final dailyScheduleProvider = FutureProvider<List<TimetableItem>>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  if (currentClass == null) return [];
  final selectedDay = ref.watch(selectedDayProvider);
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getDailySchedule(
    currentClass.code,
    selectedDay,
  );
});

// Ongoing Class
final ongoingClassProvider = FutureProvider<TimetableItem?>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  if (currentClass == null) return null;
  final repository = ref.watch(timetableRepositoryProvider);
  final item = await repository.getOngoingItem(currentClass.code);
  HomeWidgetService().updateWidgetData(ongoingClass: item);
  return item;
});

// Next Class
final nextClassProvider = FutureProvider<TimetableItem?>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  if (currentClass == null) return null;
  final repository = ref.watch(timetableRepositoryProvider);
  final item = await repository.getNextItem(currentClass.code);
  HomeWidgetService().updateWidgetData(nextClass: item);
  return item;
});

// Live ticker stream provider updating every second for countdown timers
final liveTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (count) => count);
});
