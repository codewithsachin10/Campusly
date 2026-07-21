class ClassModel {
  final String id;
  final String code; // e.g. CAMPUS-B7K2
  final String name; // e.g. Database Management Systems
  final String section; // e.g. SECTION B
  final String department; // e.g. CSBS
  final String institution; // e.g. Rajalakshmi Engineering College
  final int enrolledCount; // e.g. 62
  final String scheduleSummary; // e.g. Mon, Wed, Fri
  final String academicYear; // e.g. Academic Year 2024 • Term 2
  final String? creatorId;

  const ClassModel({
    required this.id,
    required this.code,
    required this.name,
    required this.section,
    required this.department,
    required this.institution,
    required this.enrolledCount,
    required this.scheduleSummary,
    this.academicYear = 'Academic Year 2024 • Term 2',
    this.creatorId,
  });

  ClassModel copyWith({
    String? id,
    String? code,
    String? name,
    String? section,
    String? department,
    String? institution,
    int? enrolledCount,
    String? scheduleSummary,
    String? academicYear,
    String? creatorId,
  }) {
    return ClassModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      section: section ?? this.section,
      department: department ?? this.department,
      institution: institution ?? this.institution,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      scheduleSummary: scheduleSummary ?? this.scheduleSummary,
      academicYear: academicYear ?? this.academicYear,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'section': section,
      'department': department,
      'institution': institution,
      'enrolledCount': enrolledCount,
      'scheduleSummary': scheduleSummary,
      'academicYear': academicYear,
      if (creatorId != null) 'creatorId': creatorId,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      section: json['section'] as String,
      department: json['department'] as String,
      institution: json['institution'] as String,
      enrolledCount: json['enrolledCount'] as int,
      scheduleSummary: json['scheduleSummary'] as String,
      academicYear:
          json['academicYear'] as String? ?? 'Academic Year 2024 • Term 2',
      creatorId: json['creatorId'] as String?,
    );
  }
}
