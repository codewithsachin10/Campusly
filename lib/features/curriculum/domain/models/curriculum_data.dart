import 'curriculum_item.dart';

class CurriculumData {
  final List<CurriculumItem> subjects;
  final String departmentName;
  final String batchName;
  final int currentSemester;

  CurriculumData({
    required this.subjects,
    required this.departmentName,
    required this.batchName,
    required this.currentSemester,
  });
}
