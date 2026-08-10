enum ConnectionStatus { pending, connected, blocked }

class ConnectionModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final ConnectionStatus status;
  final DateTime timestamp;

  const ConnectionModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  ConnectionModel copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    ConnectionStatus? status,
    DateTime? timestamp,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] as String? ?? '',
      requesterId: json['requesterId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.pending,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
