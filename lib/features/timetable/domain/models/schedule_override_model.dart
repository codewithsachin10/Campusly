class ScheduleOverrideModel {
  final String id;
  final String dateString; // '2026-07-20'
  final String targetItemId; // original timetable item ID or hour slot
  final String newTitle;
  final String newInstructor;
  final String newRoom;
  final bool isCancelled;

  const ScheduleOverrideModel({
    required this.id,
    required this.dateString,
    required this.targetItemId,
    required this.newTitle,
    required this.newInstructor,
    required this.newRoom,
    this.isCancelled = false,
  });

  factory ScheduleOverrideModel.fromJson(Map<String, dynamic> json) {
    return ScheduleOverrideModel(
      id: json['id'] as String? ?? '',
      dateString: json['dateString'] as String? ?? '',
      targetItemId: json['targetItemId'] as String? ?? '',
      newTitle: json['newTitle'] as String? ?? '',
      newInstructor: json['newInstructor'] as String? ?? '',
      newRoom: json['newRoom'] as String? ?? '',
      isCancelled: json['isCancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateString': dateString,
    'targetItemId': targetItemId,
    'newTitle': newTitle,
    'newInstructor': newInstructor,
    'newRoom': newRoom,
    'isCancelled': isCancelled,
  };
}
