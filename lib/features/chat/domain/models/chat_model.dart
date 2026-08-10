enum ChatType { private, group, community }

class ChatModel {
  final String id;
  final ChatType type;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, dynamic>?
  groupMetadata; // name, description, avatarUrl, adminIds

  const ChatModel({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.groupMetadata,
  });

  ChatModel copyWith({
    String? id,
    ChatType? type,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, dynamic>? groupMetadata,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      groupMetadata: groupMetadata ?? this.groupMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'groupMetadata': groupMetadata,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String? ?? '',
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.private,
      ),
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'] as String)
          : null,
      groupMetadata: json['groupMetadata'] as Map<String, dynamic>?,
    );
  }
}
