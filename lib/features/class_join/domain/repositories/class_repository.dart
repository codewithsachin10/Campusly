import '../models/class_model.dart';

abstract class ClassRepository {
  Future<List<ClassModel>> getAllClasses();
  Future<ClassModel?> getClassByCode(String code);
  Future<List<ClassModel>> searchClasses(String query, {String? department});
  Future<ClassModel> createClass({
    required String name,
    required String section,
    required String department,
    required String institution,
    required String scheduleSummary,
  });
}
