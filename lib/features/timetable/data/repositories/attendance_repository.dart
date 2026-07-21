import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;
  static final Map<String, AttendanceModel> _memoryCache = {};

  AttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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
      final savedJson = prefs.getString('attendance_$cacheKey');
      if (savedJson != null && savedJson.isNotEmpty) {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        final model = AttendanceModel.fromJson(map);
        _memoryCache[cacheKey] = model;
        _triggerBackgroundSync(userId, cleanCode, subjectName);
        return model;
      }
    } catch (_) {}

    // 3. Fast Firestore local cache check
    try {
      final docSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(cleanCode)
          .get(const GetOptions(source: Source.cache));
      if (docSnap.exists && docSnap.data() != null) {
        final model = AttendanceModel.fromJson(docSnap.data()!);
        _saveToLocal(cacheKey, model);
        _triggerBackgroundSync(userId, cleanCode, subjectName);
        return model;
      }
    } catch (_) {}

    // 4. Network query with fast 3s timeout
    try {
      final docSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(cleanCode)
          .get()
          .timeout(const Duration(seconds: 3));
      if (docSnap.exists && docSnap.data() != null) {
        final model = AttendanceModel.fromJson(docSnap.data()!);
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

  void _triggerBackgroundSync(String userId, String subjectCode, String subjectName) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final docSnap = await _firestore
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .doc(subjectCode)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 4));
        if (docSnap.exists && docSnap.data() != null) {
          final model = AttendanceModel.fromJson(docSnap.data()!);
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(cleanCode)
          .set(model.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Attendance saved locally. Firestore sync error/offline: $e');
    }
  }

  void _saveToLocal(String cacheKey, AttendanceModel model) {
    _memoryCache[cacheKey] = model;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('attendance_$cacheKey', jsonEncode(model.toJson()));
    }).catchError((_) {});
  }
}
