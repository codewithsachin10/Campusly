import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/class_model.dart';
import '../../domain/repositories/class_repository.dart';

class SupabaseClassRepository implements ClassRepository {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();
  static final Map<String, ClassModel> _memoryClasses = {};
  static List<ClassModel>? _memoryAllClasses;

  SupabaseClassRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<ClassModel>> getAllClasses() async {
    if (_memoryAllClasses != null && _memoryAllClasses!.isNotEmpty) {
      _triggerBackgroundAllClassesSync();
      return _memoryAllClasses!;
    }

    try {
      final response = await _supabase
          .from('sections')
          .select()
          .timeout(const Duration(seconds: 15));

      if (response.isEmpty) {
        return [];
      }

      final classes = response.map((row) => _mapRowToClassModel(row)).toList();
      _memoryAllClasses = classes;
      for (final c in classes) {
        _memoryClasses[c.code.toUpperCase()] = c;
      }
      return classes;
    } catch (e) {
      debugPrint('Error fetching classes from Supabase: $e');
      if (_memoryAllClasses != null && _memoryAllClasses!.isNotEmpty) {
        return _memoryAllClasses!;
      }
      return [];
    }
  }

  void _triggerBackgroundAllClassesSync() {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final response = await _supabase
            .from('sections')
            .select()
            .timeout(const Duration(seconds: 15));
        if (response.isNotEmpty) {
          _memoryAllClasses = response
              .map((row) => _mapRowToClassModel(row))
              .toList();
          for (final c in _memoryAllClasses!) {
            _memoryClasses[c.code.toUpperCase()] = c;
          }
        }
      } catch (_) {}
    });
  }

  @override
  Future<ClassModel?> getClassByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    if (_memoryClasses.containsKey(cleanCode)) {
      return _memoryClasses[cleanCode];
    }


    try {
      final response = await _supabase
          .from('sections')
          .select()
          .ilike('code', cleanCode)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response != null) {
        final model = _mapRowToClassModel(response);
        _memoryClasses[cleanCode] = model;
        return model;
      }

      final all = await getAllClasses();
      try {
        final found = all.firstWhere((c) => c.code.toUpperCase() == cleanCode);
        _memoryClasses[cleanCode] = found;
        return found;
      } catch (_) {
        return _memoryClasses[cleanCode];
      }
    } catch (e) {
      debugPrint('Error fetching class by code offline/timeout: $e');
      return _memoryClasses[cleanCode];
    }
  }

  @override
  Future<List<ClassModel>> searchClasses(
    String query, {
    String? department,
  }) async {
    final all = await getAllClasses();
    final cleanQuery = query.trim().toLowerCase();

    return all.where((c) {
      final matchesQuery =
          cleanQuery.isEmpty ||
          c.name.toLowerCase().contains(cleanQuery) ||
          c.code.toLowerCase().contains(cleanQuery) ||
          c.department.toLowerCase().contains(cleanQuery) ||
          c.institution.toLowerCase().contains(cleanQuery);

      final matchesDept =
          department == null ||
          department.isEmpty ||
          department == 'All' ||
          c.department.toUpperCase() == department.toUpperCase();

      return matchesQuery && matchesDept;
    }).toList();
  }

  @override
  Future<ClassModel> createClass({
    required String name,
    required String section,
    required String department,
    required String institution,
    required String scheduleSummary,
  }) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomPart = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    final code = 'CAMPUS-$randomPart';
    final id = _uuid.v4();

    final formattedSection = section.toUpperCase().startsWith('SECTION')
        ? section.toUpperCase()
        : 'SECTION ${section.toUpperCase()}';

    final newClass = ClassModel(
      id: id,
      code: code,
      name: name,
      section: formattedSection,
      department: department,
      institution: institution,
      enrolledCount: 1,
      scheduleSummary: scheduleSummary,
      creatorId: _supabase.auth.currentUser?.id,
    );

    try {
      await _supabase.from('sections').insert({
        'id': id,
        'code': code,
        'name': name,
        'description': '$institution - $scheduleSummary',
      });
    } catch (e) {
      debugPrint('Error saving created class to Supabase: $e');
    }

    return newClass;
  }

  ClassModel _mapRowToClassModel(Map<String, dynamic> row) {
    return ClassModel(
      id: row['id'] ?? _uuid.v4(),
      code: row['code'] ?? '',
      name: row['name'] ?? 'Unnamed Class',
      section: (row['name'] as String?)?.split('-').last.trim() ?? '',
      department: row['head'] ?? 'General',
      institution: 'College',
      enrolledCount: 60,
      scheduleSummary: 'Mon — Fri',
      academicYear: 'Academic Year 2024 • Term 2',
    );
  }


}
