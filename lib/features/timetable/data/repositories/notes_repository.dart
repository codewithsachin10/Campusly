import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/note_model.dart';

class SupabaseNotesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  static final Map<String, List<NoteModel>> _memoryCache = {};

  Future<List<NoteModel>> getNotes({
    required String userId,
    required String subjectCode,
  }) async {
    final cleanCode = subjectCode.trim().toUpperCase();
    final cacheKey = '${userId}_$cleanCode';

    if (_memoryCache.containsKey(cacheKey) &&
        _memoryCache[cacheKey]!.isNotEmpty) {
      _triggerBackgroundSync(userId, cleanCode);
      return _memoryCache[cacheKey]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('v2_notes_$cacheKey');
      if (savedJson != null && savedJson.isNotEmpty) {
        final list = jsonDecode(savedJson) as List<dynamic>;
        final items = list
            .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _memoryCache[cacheKey] = items;
        _triggerBackgroundSync(userId, cleanCode);
        return items;
      }
    } catch (_) {}

    try {
      final data = await _supabase
          .from('notes')
          .select()
          .eq('student_id', userId)
          .eq('subject_code', cleanCode)
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 3));

      if (data.isNotEmpty) {
        final items = data.map((d) => _mapRowToNoteModel(d)).toList();
        _saveToLocal(cacheKey, items);
        return items;
      }
    } catch (_) {}

    return _memoryCache[cacheKey] ?? [];
  }

  void _triggerBackgroundSync(String userId, String subjectCode) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final data = await _supabase
            .from('notes')
            .select()
            .eq('student_id', userId)
            .eq('subject_code', subjectCode)
            .order('updated_at', ascending: false)
            .timeout(const Duration(seconds: 4));

        if (data.isNotEmpty) {
          final items = data.map((d) => _mapRowToNoteModel(d)).toList();
          _saveToLocal('${userId}_$subjectCode', items);
        }
      } catch (_) {}
    });
  }

  Future<NoteModel> addOrUpdateNote({
    required String userId,
    required String subjectCode,
    String? existingId,
    required String title,
    required String content,
  }) async {
    final cleanCode = subjectCode.trim().toUpperCase();
    final cacheKey = '${userId}_$cleanCode';
    final noteId = existingId ?? _uuid.v4();

    final newNote = NoteModel(
      id: noteId,
      subjectCode: cleanCode,
      title: title,
      content: content,
      updatedAt: DateTime.now(),
    );

    final currentList = List<NoteModel>.from(_memoryCache[cacheKey] ?? []);
    final index = currentList.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      currentList[index] = newNote;
    } else {
      currentList.insert(0, newNote);
    }
    _saveToLocal(cacheKey, currentList);

    try {
      await _supabase
          .from('notes')
          .upsert({
            'id': noteId,
            'student_id': userId,
            'subject_code': cleanCode,
            'title': title,
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Note saved locally. Supabase sync offline/error: $e');
    }

    return newNote;
  }

  Future<void> deleteNote({
    required String userId,
    required String subjectCode,
    required String noteId,
  }) async {
    final cleanCode = subjectCode.trim().toUpperCase();
    final cacheKey = '${userId}_$cleanCode';

    final currentList = List<NoteModel>.from(_memoryCache[cacheKey] ?? []);
    currentList.removeWhere((n) => n.id == noteId);
    _saveToLocal(cacheKey, currentList);

    try {
      await _supabase
          .from('notes')
          .delete()
          .eq('id', noteId)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Note deleted locally. Supabase sync offline/error: $e');
    }
  }

  void _saveToLocal(String cacheKey, List<NoteModel> items) {
    _memoryCache[cacheKey] = items;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        'v2_notes_$cacheKey',
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    }).catchError((_) {});
  }

  NoteModel _mapRowToNoteModel(Map<String, dynamic> row) {
    return NoteModel(
      id: row['id'],
      subjectCode: row['subject_code'] ?? '',
      title: row['title'] ?? '',
      content: row['content'] ?? '',
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'])
          : DateTime.now(),
    );
  }
}
