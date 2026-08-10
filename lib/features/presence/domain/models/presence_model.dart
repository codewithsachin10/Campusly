class PresenceModel {
  final String userId;
  final String location; // 'Library', 'Canteen', 'CS Block'
  final String visibility; // 'Hidden', 'Friends', 'Classmates', 'Everyone'
  final double? latitude;
  final double? longitude;
  final DateTime expiresAt;
  final DateTime updatedAt;
  final String
  onlineStatus; // 'Online', 'In Class', 'Do Not Disturb', 'Offline'

  const PresenceModel({
    required this.userId,
    required this.location,
    required this.visibility,
    this.latitude,
    this.longitude,
    required this.expiresAt,
    required this.updatedAt,
    this.onlineStatus = 'Online',
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'location': location,
      'visibility': visibility,
      'latitude': latitude,
      'longitude': longitude,
      'expiresAt': expiresAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'onlineStatus': onlineStatus,
    };
  }

  factory PresenceModel.fromJson(Map<String, dynamic> json) {
    return PresenceModel(
      userId: json['userId'] as String? ?? '',
      location: json['location'] as String? ?? 'Unknown',
      visibility: json['visibility'] as String? ?? 'Hidden',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      onlineStatus: json['onlineStatus'] as String? ?? 'Offline',
    );
  }
}
