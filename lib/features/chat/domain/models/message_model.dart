enum MessageType { text, image, document, voice }

enum MessageStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final MessageType type;
  final MessageStatus status;
  final String? replyToMessageId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // e.g. file URL, file name, duration
  final String? localStatus; // e.g. pending, failed (offline-first)

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.status,
    this.replyToMessageId,
    required this.timestamp,
    this.metadata,
    this.localStatus,
  });

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    MessageStatus? status,
    String? replyToMessageId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? localStatus,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      localStatus: localStatus ?? this.localStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'status': status.name,
      'replyToMessageId': replyToMessageId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'localStatus': localStatus,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      replyToMessageId: json['replyToMessageId'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      localStatus: json['localStatus'] as String?,
    );
  }
}
