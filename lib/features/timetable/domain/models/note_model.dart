class NoteModel {
  final String id;
  final String subjectCode;
  final String title;
  final String content;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.subjectCode,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? subjectCode,
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectCode': subjectCode,
    'title': title,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
