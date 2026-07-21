import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/class_model.dart';
import '../../domain/repositories/class_repository.dart';
import '../../data/repositories/firebase_class_repository.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return FirebaseClassRepository();
});

// Holds the currently active joined class for the user with SharedPreferences persistence
class CurrentClassNotifier extends Notifier<ClassModel?> {
  static const _storageKey = 'saved_joined_class_code';
  static const _jsonStorageKey = 'saved_joined_class_json';

  @override
  ClassModel? build() {
    // Load saved class synchronously from local JSON right away for instant offline UI
    _loadSavedClass();
    return null;
  }

  Future<void> _loadSavedClass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Instant local load (< 5ms) so offline users never see spinners
      final savedJson = prefs.getString(_jsonStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        try {
          final map = jsonDecode(savedJson) as Map<String, dynamic>;
          state = ClassModel.fromJson(map);
        } catch (_) {}
      }

      // 2. Background sync with cache/server without blocking UI
      final savedCode = prefs.getString(_storageKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        final repository = ref.read(classRepositoryProvider);
        final classModel = await repository.getClassByCode(savedCode);
        if (classModel != null) {
          state = classModel;
          await prefs.setString(_jsonStorageKey, jsonEncode(classModel.toJson()));
        }
      }
    } catch (e) {
      debugPrint('Error loading saved class from SharedPreferences: $e');
    }
  }

  Future<void> joinClass(ClassModel classModel) async {
    state = classModel;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, classModel.code);
      await prefs.setString(_jsonStorageKey, jsonEncode(classModel.toJson()));
    } catch (e) {
      debugPrint('Error saving joined class to SharedPreferences: $e');
    }
  }

  Future<void> leaveClass() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_jsonStorageKey);
    } catch (e) {
      debugPrint('Error removing saved class from SharedPreferences: $e');
    }
  }
}

final currentClassProvider =
    NotifierProvider<CurrentClassNotifier, ClassModel?>(() {
      return CurrentClassNotifier();
    });

// Search and lookup state controller
class ClassController extends AsyncNotifier<List<ClassModel>> {
  @override
  Future<List<ClassModel>> build() async {
    final repository = ref.watch(classRepositoryProvider);
    return await repository.getAllClasses();
  }

  Future<void> search(String query, {String? department}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      return await repository.searchClasses(query, department: department);
    });
  }

  Future<ClassModel?> lookupByCode(String code) async {
    final repository = ref.read(classRepositoryProvider);
    return await repository.getClassByCode(code);
  }

  Future<ClassModel?> createAndJoin({
    required String name,
    required String section,
    required String department,
    required String institution,
    required String scheduleSummary,
  }) async {
    try {
      final repository = ref.read(classRepositoryProvider);
      final created = await repository.createClass(
        name: name,
        section: section,
        department: department,
        institution: institution,
        scheduleSummary: scheduleSummary,
      );
      ref.read(currentClassProvider.notifier).joinClass(created);
      // Refresh class list if possible without clobbering state
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, created]);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

final classControllerProvider =
    AsyncNotifierProvider<ClassController, List<ClassModel>>(() {
      return ClassController();
    });
