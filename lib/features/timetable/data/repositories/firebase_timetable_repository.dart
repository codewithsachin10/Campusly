import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/timetable_item.dart';
import '../../domain/repositories/timetable_repository.dart';

class FirebaseTimetableRepository implements TimetableRepository {
  final FirebaseFirestore _firestore;
  static final Map<String, List<TimetableItem>> _memoryCache = {};
  static final Set<String> _syncingKeys = {};

  FirebaseTimetableRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<TimetableItem>> _fetchScheduleForClass(
    String classCodeOrId,
  ) async {
    final normalized = classCodeOrId.trim().toUpperCase();

    // 1. Instant In-Memory Cache Check (< 1 ms lag)
    if (_memoryCache.containsKey(normalized) && _memoryCache[normalized]!.isNotEmpty) {
      _triggerBackgroundSync(classCodeOrId);
      return _memoryCache[normalized]!;
    }

    // 2. Local SharedPreferences Cache Check (< 5 ms lag)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('cached_schedule_$normalized') ??
          prefs.getString('cached_schedule_SECTION-B') ??
          prefs.getString('cached_schedule_CAMPUS-CSBS-B1');
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

    // 3. Fast Firestore Local Cache Check
    try {
      final items = await _queryFirestoreSchedule(classCodeOrId, source: Source.cache);
      if (items.isNotEmpty) {
        _saveToLocalCache(normalized, items);
        _triggerBackgroundSync(classCodeOrId);
        return items;
      }
    } catch (e) {
      debugPrint('Firestore local cache miss: $e');
    }

    // 4. Fallback: Network Query with 3-second timeout to never freeze when offline
    try {
      final items = await _queryFirestoreSchedule(classCodeOrId, source: Source.serverAndCache)
          .timeout(const Duration(seconds: 3), onTimeout: () => []);
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
        final items = await _queryFirestoreSchedule(classCodeOrId, source: Source.server)
            .timeout(const Duration(seconds: 4), onTimeout: () => []);
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
    SharedPreferences.getInstance().then((prefs) {
      final jsonStr = jsonEncode(items.map((i) => i.toJson()).toList());
      prefs.setString('cached_schedule_$normalized', jsonStr);
      if (normalized == 'SECTION-B' || normalized == 'CAMPUS-CSBS-B1') {
        prefs.setString('cached_schedule_SECTION-B', jsonStr);
        prefs.setString('cached_schedule_CAMPUS-CSBS-B1', jsonStr);
      }
    }).catchError((_) {});
  }

  Future<List<TimetableItem>> _queryFirestoreSchedule(
    String classCodeOrId, {
    required Source source,
  }) async {
    final normalized = classCodeOrId.trim().toUpperCase();

    // Check direct doc ID first
    var snapshot = await _firestore
        .collection('classes')
        .doc(classCodeOrId)
        .collection('schedule')
        .get(GetOptions(source: source));

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => TimetableItem.fromJson(doc.data())).toList();
    }

    // Lookup by code if direct ID missed
    final classQuery = await _firestore
        .collection('classes')
        .where('code', isEqualTo: normalized)
        .limit(1)
        .get(GetOptions(source: source));

    if (classQuery.docs.isNotEmpty) {
      final realId = classQuery.docs.first.id;
      snapshot = await _firestore
          .collection('classes')
          .doc(realId)
          .collection('schedule')
          .get(GetOptions(source: source));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => TimetableItem.fromJson(doc.data())).toList();
      }
    }

    // Special fallback for section-b if not found by direct or where query
    if (normalized == 'CAMPUS-CSBS-B1' || normalized == 'SECTION-B') {
      snapshot = await _firestore
          .collection('classes')
          .doc('section-b')
          .collection('schedule')
          .get(GetOptions(source: source));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => TimetableItem.fromJson(doc.data())).toList();
      }
    }

    return [];
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
        all.where((i) =>
            i.dayOfWeek.toLowerCase() == todayStr &&
            !i.isBreak &&
            i.category.toLowerCase() != 'break').toList()..sort(
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
          all.where((i) =>
              i.dayOfWeek.toLowerCase() == nextDayStr &&
              !i.isBreak &&
              i.category.toLowerCase() != 'break').toList()..sort(
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
