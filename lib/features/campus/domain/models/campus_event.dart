class CampusEvent {
  final String id;
  final String title;
  final String? description;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  final String? category;
  final List<String>? participants; // userIds

  const CampusEvent({
    required this.id,
    required this.title,
    this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    this.category,
    this.participants,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'category': category,
      'participants': participants,
    };
  }

  factory CampusEvent.fromJson(Map<String, dynamic> json) {
    return CampusEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      locationName: json['locationName'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['endTime'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      category: json['category'] as String?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
