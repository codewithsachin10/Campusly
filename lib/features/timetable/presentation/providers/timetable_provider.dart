import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../../domain/models/custom_timetable_membership.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../../data/repositories/supabase_timetable_repository.dart';
import 'package:flutter/widgets.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return SupabaseTimetableRepository();
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
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getWeeklySchedule(currentClass?.code ?? "");
});

// Daily schedule for strictly TODAY (`DateTime.now().weekday`)
final todayScheduleProvider = FutureProvider<List<TimetableItem>>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
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
  return repository.getDailySchedule(currentClass?.code ?? "", todayStr);
});

// Daily schedule for the active day tab (`selectedDayProvider`)
final dailyScheduleProvider = FutureProvider<List<TimetableItem>>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  final selectedDay = ref.watch(selectedDayProvider);
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getDailySchedule(currentClass?.code ?? "", selectedDay);
});

// Ongoing Class
final ongoingClassProvider = FutureProvider<TimetableItem?>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getOngoingItem(currentClass?.code ?? "");
});

// Next Class
final nextClassProvider = FutureProvider<TimetableItem?>((ref) async {
  final currentClass = ref.watch(currentClassProvider);
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getNextItem(currentClass?.code ?? "");
});

// Snapshot of ongoing + next class for debounced widget updates
final widgetScheduleSnapshotProvider =
    Provider<({TimetableItem? ongoing, TimetableItem? next})>((ref) {
      final ongoing = ref.watch(ongoingClassProvider).value;
      final next = ref.watch(nextClassProvider).value;
      return (ongoing: ongoing, next: next);
    });

class _TickerLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;
  final VoidCallback onPaused;

  _TickerLifecycleObserver({required this.onResumed, required this.onPaused});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    } else {
      onPaused();
    }
  }
}

// Live ticker stream provider updating every second for countdown timers
// AutoDisposed, aligned to second boundaries, pauses when app is paused
final liveTickerProvider = StreamProvider.autoDispose<int>((ref) {
  final controller = StreamController<int>();
  Timer? timer;
  Timer? initialTimer;
  var count = 0;
  var isResumed =
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void stopTimers() {
    initialTimer?.cancel();
    initialTimer = null;
    timer?.cancel();
    timer = null;
  }

  void startPeriodic() {
    stopTimers();
    final msUntilNextSecond = 1000 - DateTime.now().millisecond;
    initialTimer = Timer(Duration(milliseconds: msUntilNextSecond), () {
      if (controller.isClosed || !isResumed) return;
      controller.add(count++);
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (controller.isClosed || !isResumed) return;
        controller.add(count++);
      });
    });
  }

  final observer = _TickerLifecycleObserver(
    onResumed: () {
      isResumed = true;
      startPeriodic();
    },
    onPaused: () {
      isResumed = false;
      stopTimers();
    },
  );

  WidgetsBinding.instance.addObserver(observer);
  if (isResumed || WidgetsBinding.instance.lifecycleState == null) {
    isResumed = true;
    startPeriodic();
  }

  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    stopTimers();
    controller.close();
  });

  return controller.stream;
});

// Joined custom timetables for the user
final joinedCustomTimetablesProvider = FutureProvider<List<CustomTimetableMembership>>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getJoinedCustomTimetables();
});
