class FacultyModel {
  final String id;
  final String name;
  final String subjectCode;
  final String subjectName;
  final String officeRoom;
  final String contactNumber;
  final String email;

  const FacultyModel({
    required this.id,
    required this.name,
    required this.subjectCode,
    required this.subjectName,
    required this.officeRoom,
    required this.contactNumber,
    required this.email,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final nameVal = json['name'] as String? ?? '';
    final deptVal = json['department'] as String? ?? '';
    final codeVal =
        json['subjectCode'] as String? ?? (deptVal.isNotEmpty ? deptVal : '');
    return FacultyModel(
      id: docId ?? json['id'] as String? ?? '',
      name: nameVal,
      subjectCode: codeVal,
      subjectName: json['subjectName'] as String? ?? deptVal,
      officeRoom:
          json['officeRoom'] as String? ?? json['cabin'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'officeRoom': officeRoom,
    'cabin': officeRoom,
    'contactNumber': contactNumber,
    'email': email,
    'department': subjectCode,
  };
}
