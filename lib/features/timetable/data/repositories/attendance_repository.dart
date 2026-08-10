import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/attendance_model.dart';

class SupabaseAttendanceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final Map<String, AttendanceModel> _memoryCache = {};

  Future<AttendanceModel> getAttendance({
    required String userId,
    required String subjectCode,
    required String subjectName,
  }) async {
    final cleanCode = subjectCode.trim().toUpperCase();
    final cacheKey = '${userId}_$cleanCode';

    // 1. Memory cache check
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. SharedPreferences local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('v2_attendance_$cacheKey');
      if (savedJson != null && savedJson.isNotEmpty) {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        final model = AttendanceModel.fromJson(map);
        _memoryCache[cacheKey] = model;
        _triggerBackgroundSync(userId, cleanCode, subjectName);
        return model;
      }
    } catch (_) {}

    // 3. Network query
    try {
      final data = await _supabase
          .from('attendance')
          .select()
          .eq('student_id', userId)
          .eq('subject_code', cleanCode)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (data != null) {
        final model = AttendanceModel.fromJson(data);
        _saveToLocal(cacheKey, model);
        return model;
      }
    } catch (_) {}

    // Default initial model if never tracked before
    final initial = AttendanceModel(
      subjectCode: cleanCode,
      subjectName: subjectName,
      presentCount: 0,
      totalCount: 0,
      history: const [],
    );
    _memoryCache[cacheKey] = initial;
    return initial;
  }

  void _triggerBackgroundSync(
    String userId,
    String subjectCode,
    String subjectName,
  ) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final data = await _supabase
            .from('attendance')
            .select()
            .eq('student_id', userId)
            .eq('subject_code', subjectCode)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));

        if (data != null) {
          final model = AttendanceModel.fromJson(data);
          _saveToLocal('${userId}_$subjectCode', model);
        }
      } catch (_) {}
    });
  }

  Future<void> saveAttendance({
    required String userId,
    required AttendanceModel model,
  }) async {
    final cleanCode = model.subjectCode.trim().toUpperCase();
    final cacheKey = '${userId}_$cleanCode';
    _saveToLocal(cacheKey, model);

    try {
      final data = model.toJson();
      data['student_id'] = userId;
      data['subject_code'] = cleanCode;

      await _supabase
          .from('attendance')
          .upsert(data)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Attendance saved locally. Supabase sync error/offline: $e');
    }
  }

  void _saveToLocal(String cacheKey, AttendanceModel model) {
    _memoryCache[cacheKey] = model;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('v2_attendance_$cacheKey', jsonEncode(model.toJson()));
    }).catchError((_) {});
  }
}
