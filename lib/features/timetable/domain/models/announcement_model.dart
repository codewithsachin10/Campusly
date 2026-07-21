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
    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      author: json['author'] as String? ?? 'Admin / CR',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      priority: json['priority'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'author': author,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority,
  };
}
