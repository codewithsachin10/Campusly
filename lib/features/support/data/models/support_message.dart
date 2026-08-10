class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderType;
  final String message;
  final List<String>? attachmentUrls;
  final bool isInternal;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.attachmentUrls,
    required this.isInternal,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      ticketId: json['ticket_id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      message: json['message'],
      attachmentUrls: json['attachment_urls'] != null 
          ? List<String>.from(json['attachment_urls']) 
          : null,
      isInternal: json['is_internal'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message': message,
      'attachment_urls': attachmentUrls,
      'is_internal': isInternal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
