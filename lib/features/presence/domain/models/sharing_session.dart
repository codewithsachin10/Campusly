class SharingSession {
  final String id;
  final String userId;
  final String visibility; // 'Friends', 'Classmates', 'Everyone'
  final DateTime startedAt;
  final DateTime expiresAt;

  const SharingSession({
    required this.id,
    required this.userId,
    required this.visibility,
    required this.startedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'visibility': visibility,
      'startedAt': startedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory SharingSession.fromJson(Map<String, dynamic> json) {
    return SharingSession(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      visibility: json['visibility'] as String? ?? 'Friends',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
