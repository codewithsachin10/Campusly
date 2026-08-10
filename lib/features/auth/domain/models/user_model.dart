class UserModel {
  final String id;
  final String name;
  final String? department;
  final String email;
  final String? avatarUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  final String? phone;
  final String? section;
  final String? year;
  final String? rollNumber;
  final String? status;
  
  // Profile onboarding fields
  final bool isProfileCompleted;
  final String? gender;
  final DateTime? dob;
  final String? emergencyContact;

  // Campusly Connect fields
  final List<String> skills;
  final List<String> interests;
  final bool isOnline;
  final DateTime? lastSeen;
  final Map<String, dynamic> privacySettings;

  const UserModel({
    required this.id,
    required this.name,
    this.department,
    required this.email,
    this.avatarUrl,
    this.isEmailVerified = false,
    required this.createdAt,
    this.phone,
    this.section,
    this.year,
    this.rollNumber,
    this.status,
    this.isProfileCompleted = false,
    this.gender,
    this.dob,
    this.emergencyContact,
    this.skills = const [],
    this.interests = const [],
    this.isOnline = false,
    this.lastSeen,
    this.privacySettings = const {},
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? department,
    String? email,
    String? avatarUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    String? phone,
    String? section,
    String? year,
    String? rollNumber,
    String? status,
    bool? isProfileCompleted,
    String? gender,
    DateTime? dob,
    String? emergencyContact,
    List<String>? skills,
    List<String>? interests,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, dynamic>? privacySettings,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      section: section ?? this.section,
      year: year ?? this.year,
      rollNumber: rollNumber ?? this.rollNumber,
      status: status ?? this.status,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'email': email,
      'avatarUrl': avatarUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'phone': phone,
      'section': section,
      'year': year,
      'rollNumber': rollNumber,
      'status': status,
      'is_profile_completed': isProfileCompleted,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'emergency_contact': emergencyContact,
      'skills': skills,
      'interests': interests,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'privacySettings': privacySettings,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      phone: json['phone'] as String?,
      section: json['section'] as String?,
      year: json['year'] as String?,
      rollNumber: json['rollNumber'] as String?,
      status: json['status'] as String?,
      isProfileCompleted: json['is_profile_completed'] as bool? ?? false,
      gender: json['gender'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      emergencyContact: json['emergency_contact'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
      privacySettings: json['privacySettings'] as Map<String, dynamic>? ?? const {},
    );
  }
}
