class CustomTimetableMembership {
  final String id;
  final String timetableId;
  final String title;
  final String description;
  final String hostName;
  final String joinCode;

  CustomTimetableMembership({
    required this.id,
    required this.timetableId,
    required this.title,
    required this.description,
    required this.hostName,
    required this.joinCode,
  });

  factory CustomTimetableMembership.fromMap(Map<String, dynamic> map) {
    return CustomTimetableMembership(
      id: map['id']?.toString() ?? '',
      timetableId: map['timetable_id']?.toString() ?? '',
      title: map['custom_timetables']?['title']?.toString() ?? map['custom_timetables']?['name']?.toString() ?? 'Custom Timetable',
      description: map['custom_timetables']?['description']?.toString() ?? '',
      hostName: map['custom_timetables']?['host_name']?.toString() ?? 'Host',
      joinCode: map['custom_timetables']?['join_code']?.toString() ?? '',
    );
  }
}
