import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/timetable_item.dart';
import '../../domain/models/custom_timetable_membership.dart';
import '../../domain/repositories/timetable_repository.dart';

class SupabaseTimetableRepository implements TimetableRepository {
  final SupabaseClient _supabase;
  static final Map<String, List<TimetableItem>> _memoryCache = {};
  static final Map<int, Map<String, dynamic>> _periodsCache = {};
  static final Set<String> _syncingKeys = {};

  SupabaseTimetableRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<List<TimetableItem>> _fetchScheduleForClass(
    String classCodeOrId,
  ) async {
    final normalized = classCodeOrId.trim().toUpperCase();

    // 1. Instant In-Memory Cache Check (< 1 ms lag)
    if (_memoryCache.containsKey(normalized) &&
        _memoryCache[normalized]!.isNotEmpty) {
      _triggerBackgroundSync(classCodeOrId);
      return _memoryCache[normalized]!;
    }

    // 2. Local SharedPreferences Cache Check (< 5 ms lag)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson =
          prefs.getString('v2_cached_schedule_$normalized') ??
          prefs.getString('v2_cached_schedule_SECTION-B') ??
          prefs.getString('v2_cached_schedule_CAMPUS-CSBS-B1');
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        final items = list.map((item) => TimetableItem.fromJson(item)).toList();
        if (items.isNotEmpty) {
          _memoryCache[normalized] = items;
          _triggerBackgroundSync(classCodeOrId);
          return items;
        }
      }
    } catch (e) {
      debugPrint('Error reading schedule local cache: $e');
    }

    // 3. Fallback: Network Query with 3-second timeout to never freeze when offline
    try {
      final items = await _querySupabaseSchedule(
        classCodeOrId,
      ).timeout(const Duration(seconds: 3), onTimeout: () => []);
      if (items.isNotEmpty) {
        _saveToLocalCache(normalized, items);
        return items;
      }
    } catch (e) {
      debugPrint('Error fetching schedule from server/timeout: $e');
    }

    return _memoryCache[normalized] ?? [];
  }

  void _triggerBackgroundSync(String classCodeOrId) {
    final normalized = classCodeOrId.trim().toUpperCase();
    if (_syncingKeys.contains(normalized)) return;
    _syncingKeys.add(normalized);

    Future.delayed(const Duration(milliseconds: 200), () async {
      try {
        final items = await _querySupabaseSchedule(
          classCodeOrId,
        ).timeout(const Duration(seconds: 4), onTimeout: () => []);
        if (items.isNotEmpty) {
          _saveToLocalCache(normalized, items);
        }
      } catch (_) {
        // Ignore background offline errors
      } finally {
        _syncingKeys.remove(normalized);
      }
    });
  }

  void _saveToLocalCache(String normalized, List<TimetableItem> items) {
    _memoryCache[normalized] = items;
    // Also bind common section codes
    if (normalized == 'SECTION-B' || normalized == 'CAMPUS-CSBS-B1') {
      _memoryCache['SECTION-B'] = items;
      _memoryCache['CAMPUS-CSBS-B1'] = items;
    }
    SharedPreferences.getInstance()
        .then((prefs) {
          final jsonStr = jsonEncode(items.map((i) => i.toJson()).toList());
          prefs.setString('v2_cached_schedule_$normalized', jsonStr);
          if (normalized == 'SECTION-B' || normalized == 'CAMPUS-CSBS-B1') {
            prefs.setString('v2_cached_schedule_SECTION-B', jsonStr);
            prefs.setString('v2_cached_schedule_CAMPUS-CSBS-B1', jsonStr);
          }
        })
        .catchError((_) {});
  }

  Future<List<TimetableItem>> _querySupabaseSchedule(
    String classCodeOrId,
  ) async {
    final normalized = classCodeOrId.trim().toUpperCase();

    // Normalization mapping to match DB
    String dbKey = normalized;
    if (normalized == 'CAMPUS-CSBS-B1' || normalized == 'SECTION-B') {
      dbKey = 'section-b';
    }

    await _fetchPeriods();

    // 1. Fetch base schedule
    final data = await _supabase
        .from('schedule')
        .select()
        .ilike('sectionKey', dbKey);

    List<TimetableItem> items = data.map((row) => _mapSupabaseRowToTimetableItem(row)).toList();

    // 2. Fetch custom timetables for current user
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final memberships = await _supabase
            .from('student_timetable_members')
            .select('timetable_id')
            .eq('student_id', user.id);
        
        if (memberships.isNotEmpty) {
          final timetableIds = memberships.map((m) => m['timetable_id']).toList();
          
          final customPeriods = await _supabase
              .from('custom_timetable_periods')
              .select('*, custom_timetables!inner(status)')
              .inFilter('timetable_id', timetableIds)
              .eq('custom_timetables.status', 'published');
              
          final customItems = customPeriods.map((row) => _mapCustomPeriodToTimetableItem(row)).toList();
          items.addAll(customItems);
        }
      } catch (e) {
        debugPrint('Error fetching custom timetables: $e');
      }
    }

    return items;
  }

  TimetableItem _mapCustomPeriodToTimetableItem(Map<String, dynamic> row) {
    // start_time / end_time format e.g. "09:00 AM"
    final startStr = row['start_time'] as String;
    final endStr = row['end_time'] as String;
    
    int parseHour(String timeStr) {
      try {
        final parts = timeStr.split(RegExp(r'[: ]'));
        int h = int.parse(parts[0]);
        if (timeStr.toLowerCase().contains('pm') && h != 12) h += 12;
        if (timeStr.toLowerCase().contains('am') && h == 12) h = 0;
        return h;
      } catch (_) { return 8; }
    }
    
    int parseMinute(String timeStr) {
      try {
        final parts = timeStr.split(RegExp(r'[: ]'));
        return int.parse(parts[1]);
      } catch (_) { return 0; }
    }

    final colorLabelFull = row['color_label'] as String? ?? 'Custom';
    final parts = colorLabelFull.split('|');
    final category = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Custom';
    final colorHex = parts.length > 1 ? parts[1] : null;

    return TimetableItem(
      id: row['id'] ?? '',
      title: row['subject'] ?? 'Custom Subject',
      shortTitle: (row['subject'] as String?)?.split(' ').first ?? 'CUST',
      dayOfWeek: (row['day'] as String).toLowerCase().substring(0, 3), // e.g. "Monday" -> "mon"
      startTime: startStr,
      endTime: endStr,
      startHour: parseHour(startStr),
      startMinute: parseMinute(startStr),
      endHour: parseHour(endStr),
      endMinute: parseMinute(endStr),
      category: category,
      room: row['room'] ?? '',
      instructor: row['faculty'] ?? '',
      isBreak: false,
      subjectCode: colorHex, // Pass hex color here
    );
  }

  TimetableItem _mapSupabaseRowToTimetableItem(Map<String, dynamic> row) {
    final period = row['period'] as int? ?? 1;
    final times = _getTimesForPeriod(period);

    return TimetableItem(
      id: row['id'] ?? '',
      title: row['subject'] ?? 'Subject',
      shortTitle: (row['subject'] as String?)?.split(' ').first ?? 'SUB',
      dayOfWeek: row['day'] ?? 'mon',
      startTime: times['startTime'] as String,
      endTime: times['endTime'] as String,
      startHour: times['startHour'] as int,
      startMinute: times['startMinute'] as int,
      endHour: times['endHour'] as int,
      endMinute: times['endMinute'] as int,
      category: row['type'] ?? 'Lecture',
      room: row['room'] ?? 'TBA',
      instructor: row['faculty'] ?? 'Faculty',
      isBreak: row['type'] == 'Break',
    );
  }

  Future<void> _fetchPeriods() async {
    if (_periodsCache.isNotEmpty) return;
    try {
      final data = await _supabase.from('periods').select().order('index');
      for (var row in data) {
        final index = row['index'] as int;
        final label = row['label'] as String; // e.g. "09:00 – 10:00"
        
        final parts = label.split(RegExp(r'[-–]')).map((e) => e.trim()).toList();
        if (parts.length == 2) {
          final startParts = parts[0].split(':');
          final endParts = parts[1].split(':');
          
          final startHour = int.tryParse(startParts[0]) ?? 8;
          final startMinute = int.tryParse(startParts[1]) ?? 0;
          final endHour = int.tryParse(endParts[0]) ?? 9;
          final endMinute = int.tryParse(endParts[1]) ?? 0;
          
          String formatTime(int h, int m) {
            final suffix = h >= 12 ? 'PM' : 'AM';
            final hr12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
            return '${hr12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
          }
          
          _periodsCache[index] = {
            'startTime': formatTime(startHour, startMinute),
            'endTime': formatTime(endHour, endMinute),
            'startHour': startHour,
            'startMinute': startMinute,
            'endHour': endHour,
            'endMinute': endMinute,
          };
        }
      }
    } catch (_) {}
  }

  Map<String, dynamic> _getTimesForPeriod(int period) {
    if (_periodsCache.containsKey(period)) {
      return _periodsCache[period]!;
    }
    // Fallback if not loaded
    return {
      'startTime': '08:00 AM',
      'endTime': '09:00 AM',
      'startHour': 8,
      'startMinute': 0,
      'endHour': 9,
      'endMinute': 0,
    };
  }

  @override
  Future<List<TimetableItem>> getWeeklySchedule(String classCode) async {
    return _fetchScheduleForClass(classCode);
  }

  @override
  Future<List<TimetableItem>> getDailySchedule(
    String classCode,
    String dayOfWeek,
  ) async {
    final all = await _fetchScheduleForClass(classCode);
    final targetDay = dayOfWeek.trim().toLowerCase();
    return all
        .where((item) => item.dayOfWeek.toLowerCase() == targetDay)
        .toList();
  }

  @override
  Future<TimetableItem?> getOngoingItem(String classCode) async {
    final all = await _fetchScheduleForClass(classCode);
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final todayStr = _getDayString(now.weekday);
    final todayItems = all
        .where((i) => i.dayOfWeek.toLowerCase() == todayStr)
        .toList();

    for (final item in todayItems) {
      final startMin = item.startHour * 60 + item.startMinute;
      final endMin = item.endHour * 60 + item.endMinute;
      if (currentMinutes >= startMin && currentMinutes < endMin) {
        return item;
      }
    }

    return null;
  }

  @override
  Future<TimetableItem?> getNextItem(String classCode) async {
    final all = await _fetchScheduleForClass(classCode);
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final todayStr = _getDayString(now.weekday);

    final todayClassItems =
        all
            .where(
              (i) =>
                  i.dayOfWeek.toLowerCase() == todayStr &&
                  !i.isBreak &&
                  i.category.toLowerCase() != 'break',
            )
            .toList()
          ..sort(
            (a, b) => (a.startHour * 60 + a.startMinute).compareTo(
              b.startHour * 60 + b.startMinute,
            ),
          );

    for (final item in todayClassItems) {
      final startMin = item.startHour * 60 + item.startMinute;
      if (startMin > currentMinutes) {
        return item;
      }
    }

    // If no remaining classes today, find the first class on the next available day of the week
    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final nextWeekday = ((now.weekday - 1 + dayOffset) % 7) + 1;
      final nextDayStr = _getDayString(nextWeekday);
      final nextDayClassItems =
          all
              .where(
                (i) =>
                    i.dayOfWeek.toLowerCase() == nextDayStr &&
                    !i.isBreak &&
                    i.category.toLowerCase() != 'break',
              )
              .toList()
            ..sort(
              (a, b) => (a.startHour * 60 + a.startMinute).compareTo(
                b.startHour * 60 + b.startMinute,
              ),
            );
      if (nextDayClassItems.isNotEmpty) {
        return nextDayClassItems.first;
      }
    }

    return null;
  }

  @override
  Future<List<CustomTimetableMembership>> getJoinedCustomTimetables() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final memberships = await _supabase
          .from('student_timetable_members')
          .select('*, custom_timetables(*)')
          .eq('student_id', user.id);
      
      return memberships.map((row) => CustomTimetableMembership.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Error fetching joined custom timetables: $e');
      return [];
    }
  }

  @override
  Future<void> leaveCustomTimetable(String timetableId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('student_timetable_members')
          .delete()
          .eq('timetable_id', timetableId)
          .eq('student_id', user.id);
    } catch (e) {
      debugPrint('Error leaving custom timetable: $e');
      rethrow;
    }
  }

  String _getDayString(int weekday) {
    switch (weekday) {
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
}
