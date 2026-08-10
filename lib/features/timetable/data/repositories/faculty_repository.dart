import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/faculty_model.dart';

class SupabaseFacultyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final Map<String, FacultyModel> _memoryCache = {};

  Future<FacultyModel?> getFacultyProfile(String nameOrSubjectCode) async {
    final clean = nameOrSubjectCode.trim().toLowerCase();
    final cleanCode = nameOrSubjectCode.trim().toUpperCase();

    if (_memoryCache.containsKey(clean)) return _memoryCache[clean];
    if (_memoryCache.containsKey(cleanCode)) return _memoryCache[cleanCode];

    try {
      final data = await _supabase
          .from('faculties')
          .select()
          .timeout(const Duration(seconds: 3));

      for (final doc in data) {
        final f = _mapRowToFacultyModel(doc);
        _memoryCache[f.name.toLowerCase()] = f;
        _memoryCache[f.subjectCode.toUpperCase()] = f;
        if (f.name.toLowerCase().contains(clean) ||
            f.subjectCode.toUpperCase() == cleanCode) {
          return f;
        }
      }
    } catch (_) {}

    return null;
  }

  FacultyModel _mapRowToFacultyModel(Map<String, dynamic> row) {
    return FacultyModel(
      id: row['id'] ?? '',
      name: row['name'] ?? '',
      subjectCode: '',
      subjectName: '',
      officeRoom: row['department'] ?? '',
      contactNumber: row['phone'] ?? '',
      email: row['email'] ?? '',
    );
  }
}
