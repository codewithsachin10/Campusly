class SupportTicket {
  final String id;
  final String studentId;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String ticketNumber;
  final String? categoryId;
  final String? assignedTo;
  final String? appVersion;
  final String? osVersion;
  final String? platform;
  final String? currentScreen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? student;

  SupportTicket({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.ticketNumber,
    this.categoryId,
    this.assignedTo,
    this.appVersion,
    this.osVersion,
    this.platform,
    this.currentScreen,
    required this.createdAt,
    required this.updatedAt,
    this.student,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      studentId: json['student_id'],
      subject: json['subject'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      ticketNumber: json['ticket_number'],
      student: json['students'] as Map<String, dynamic>?,
      categoryId: json['category_id'],
      assignedTo: json['assigned_to'],
      appVersion: json['app_version'],
      osVersion: json['os_version'],
      platform: json['platform'],
      currentScreen: json['current_screen'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'subject': subject,
      'description': description,
      'priority': priority,
      'status': status,
      'ticket_number': ticketNumber,
      'category_id': categoryId,
      'assigned_to': assignedTo,
      'app_version': appVersion,
      'os_version': osVersion,
      'platform': platform,
      'current_screen': currentScreen,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
