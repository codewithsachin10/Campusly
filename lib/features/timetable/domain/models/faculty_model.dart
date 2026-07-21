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

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      officeRoom: json['officeRoom'] as String? ?? '',
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
    'contactNumber': contactNumber,
    'email': email,
  };
}
