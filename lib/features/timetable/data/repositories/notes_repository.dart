import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/note_model.dart';

class NotesRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  static final Map<String, List<NoteModel>> _memoryCache = {};

  NotesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<NoteModel>> getNotes({
    required String userId,
    required String subjectCode,
  }) async {
    final cleanCode = subjectCode.trim().toUpperCase();
    final cacheKey = '${userId}_$cleanCode';

    if (_memoryCache.containsKey(cacheKey) && _memoryCache[cacheKey]!.isNotEmpty) {
      _triggerBackgroundSync(userId, cleanCode);
      return _memoryCache[cacheKey]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('notes_$cacheKey');
      if (savedJson != null && savedJson.isNotEmpty) {
        final list = jsonDecode(savedJson) as List<dynamic>;
        final items = list.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
        _memoryCache[cacheKey] = items;
        _triggerBackgroundSync(userId, cleanCode);
        return items;
      }
    } catch (_) {}

    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(cleanCode)
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .get(const GetOptions(source: Source.cache));
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((d) => NoteModel.fromJson(d.data())).toList();
        _saveToLocal(cacheKey, items);
        _triggerBackgroundSync(userId, cleanCode);
        return items;
      }
    } catch (_) {}

    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(cleanCode)
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((d) => NoteModel.fromJson(d.data())).toList();
        _saveToLocal(cacheKey, items);
        return items;
      }
    } catch (_) {}

    return _memoryCache[cacheKey] ?? [];
  }

  void _triggerBackgroundSync(String userId, String subjectCode) {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(subjectCode)
            .collection('items')
            .orderBy('updatedAt', descending: true)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => NoteModel.fromJson(d.data())).toList();
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(cleanCode)
          .collection('items')
          .doc(noteId)
          .set(newNote.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Note saved locally. Firestore sync offline: $e');
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(cleanCode)
          .collection('items')
          .doc(noteId)
          .delete()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Note deleted locally. Firestore sync offline: $e');
    }
  }

  void _saveToLocal(String cacheKey, List<NoteModel> items) {
    _memoryCache[cacheKey] = items;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('notes_$cacheKey', jsonEncode(items.map((e) => e.toJson()).toList()));
    }).catchError((_) {});
  }
}
