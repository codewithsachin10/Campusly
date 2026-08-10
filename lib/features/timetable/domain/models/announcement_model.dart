class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String author;
  final DateTime createdAt;
  final String priority; // 'high', 'normal'

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.author,
    required this.createdAt,
    this.priority = 'normal',
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime created = DateTime.now();
    if (json['createdAt'] != null) {
      created =
          DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      created =
          DateTime.tryParse(json['created_at'] as String) ?? DateTime.now();
    }

    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Announcement',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      author:
          json['author'] as String? ??
          json['sentBy'] as String? ??
          'Controller / Admin',
      createdAt: created,
      priority: json['priority'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': message,
    'target': author,
    'priority': priority,
  };
}
