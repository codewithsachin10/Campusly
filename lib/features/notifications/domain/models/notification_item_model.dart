// NotificationItemModel
class NotificationAudienceModel {
  final String
  type; // 'everyone', 'department', 'year', 'section', 'studentIds'
  final String? departmentId;
  final String? year;
  final String? sectionId;
  final List<String> studentIds;

  const NotificationAudienceModel({
    required this.type,
    this.departmentId,
    this.year,
    this.sectionId,
    this.studentIds = const [],
  });

  factory NotificationAudienceModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const NotificationAudienceModel(type: 'everyone');
    }
    final rawIds = map['studentIds'];
    List<String> ids = [];
    if (rawIds is List) {
      ids = rawIds.map((e) => e.toString()).toList();
    }
    return NotificationAudienceModel(
      type: map['type'] as String? ?? 'everyone',
      departmentId: map['departmentId'] as String?,
      year: map['year'] as String?,
      sectionId: map['sectionId'] as String?,
      studentIds: ids,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'departmentId': departmentId,
      'year': year,
      'sectionId': sectionId,
      'studentIds': studentIds,
    };
  }
}

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final String
  category; // Announcement, Exam Reminder, Assignment Reminder, Emergency Alert, Event Reminder
  final String priority; // normal, high, emergency
  final NotificationAudienceModel targetAudience;
  final String sentBy;
  final DateTime sentAt;
  final List<String> readBy;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.targetAudience,
    required this.sentBy,
    required this.sentAt,
    this.readBy = const [],
  });

  factory NotificationItemModel.fromMap(Map<String, dynamic> data) {
    DateTime sent = DateTime.now();
    if (data['created_at'] != null) {
      sent = DateTime.tryParse(data['created_at'] as String) ?? DateTime.now();
    } else if (data['sentAt'] != null) {
      sent = DateTime.tryParse(data['sentAt'] as String) ?? DateTime.now();
    }

    final rawRead = data['readBy'];
    List<String> readList = [];
    if (rawRead is List) {
      readList = rawRead.map((e) => e.toString()).toList();
    }

    return NotificationItemModel(
      id: data['id']?.toString() ?? '',
      title: data['title'] as String? ?? 'Alert',
      message: data['body'] as String? ?? data['message'] as String? ?? '',
      category:
          data['category'] as String? ??
          (data['type'] as String? ?? 'Announcement'),
      priority: data['priority'] as String? ?? 'normal',
      targetAudience: NotificationAudienceModel.fromMap(
        data['targetAudience'] as Map<String, dynamic>?,
      ),
      sentBy: data['target'] as String? ?? data['sentBy'] as String? ?? 'Admin',
      sentAt: sent,
      readBy: readList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': message,
      'category': category,
      'priority': priority,
      'target': sentBy,
      'created_at': sentAt.toIso8601String(),
    };
  }

  bool isReadBy(String studentId) {
    if (studentId.isEmpty) return false;
    return readBy.contains(studentId);
  }
}
