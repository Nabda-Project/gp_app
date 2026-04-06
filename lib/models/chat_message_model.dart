/// Model representing a single chat message between two users.
class ChatMessageModel {
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime? timestamp;
  final String? senderName;
  bool isRead;
  bool isDelivered;

  ChatMessageModel({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.timestamp,
    this.senderName,
    this.isRead = false,
    this.isDelivered = false,
  });

  /// Create from backend JSON (REST history or STOMP payload).
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      senderName: json['senderName'] as String?,
      isRead: json['read'] as bool? ?? false,
      isDelivered: json['delivered'] as bool? ?? false,
    );
  }

  /// Convert to JSON for sending via STOMP.
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'read': isRead,
      'delivered': isDelivered,
    };
  }

  /// Whether this message was sent by the given user ID.
  bool isSentBy(int userId) => senderId == userId;
}
