class UserModel {
  final String id;
  final String name;
  final String? department;
  final String email;
  final String? avatarUrl;
  final bool isEmailVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.department,
    required this.email,
    this.avatarUrl,
    this.isEmailVerified = false,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? department,
    String? email,
    String? avatarUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
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
    );
  }
}
