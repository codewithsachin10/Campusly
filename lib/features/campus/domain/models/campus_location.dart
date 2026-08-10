class CampusLocation {
  final String id;
  final String name;
  final String category; // e.g., 'Department Building', 'Library', 'Canteen'
  final String? description;
  final double latitude;
  final double longitude;
  final String? building;
  final String? floor;
  final String? room;
  final List<String>? rooms;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.latitude,
    required this.longitude,
    this.building,
    this.floor,
    this.room,
    this.rooms,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'building': building,
      'floor': floor,
      'room': room,
      'rooms': rooms,
    };
  }

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Place',
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      building: json['building'] as String?,
      floor: json['floor'] as String?,
      room: json['room'] as String?,
      rooms: (json['rooms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
