class CurriculumItem {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String type; // e.g. "Theory" or "Lab" or "Mandatory Course"
  final String category; // e.g. "PC", "BS", "HS"
  final String lTp; // e.g. "3-0-0"
  final double credits;
  final int semester;
  final String description;
  final String prerequisites;

  CurriculumItem({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.type,
    required this.category,
    required this.lTp,
    required this.credits,
    required this.semester,
    this.description = 'An introduction to the fundamental concepts and practical applications. Topics include core principles, real-world examples, and foundational techniques required for advanced study.',
    this.prerequisites = 'None required for this course.',
  });

  bool get isLab => type.toLowerCase().contains('lab') || category.toLowerCase() == 'lab' || lTp.endsWith('-2') || lTp.endsWith('-4');
  bool get isTheory => !isLab;

  factory CurriculumItem.fromMap(Map<String, dynamic> map) {
    return CurriculumItem(
      id: map['id']?.toString() ?? '',
      subjectCode: (map['code'] ?? map['subject_code'])?.toString() ?? '',
      subjectName: (map['subject_name'] ?? map['name'])?.toString() ?? '',
      type: map['type']?.toString() ?? 'Theory',
      category: map['category']?.toString() ?? 'Core Course',
      lTp: map['l_t_p']?.toString() ?? '3-0-0',
      credits: double.tryParse(map['credits']?.toString() ?? '3.0') ?? 3.0,
      semester: int.tryParse(map['semester']?.toString() ?? '1') ?? 1,
      description: map['description']?.toString() ?? 'An introduction to the fundamental concepts and practical applications. Topics include core principles, real-world examples, and foundational techniques required for advanced study.',
      prerequisites: map['prerequisites']?.toString() ?? 'None required for this course.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'type': type,
      'category': category,
      'l_t_p': lTp,
      'credits': credits,
      'semester': semester,
      'description': description,
      'prerequisites': prerequisites,
    };
  }
}
