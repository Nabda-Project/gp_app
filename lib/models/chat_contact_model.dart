/// Matches back-end `ChatContactDTO`.
/// Returned by `GET /api/chat/conversations/{userId}`.
/// Represents a chat partner with conversation summary (last message, unread count).
class ChatContactModel {
  final int partnerId;
  final String partnerName;
  final String partnerEmail;
  final String lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final String? partnerProfileImageUrl;

  ChatContactModel({
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    required this.lastMessage,
    this.lastMessageTimestamp,
    required this.unreadCount,
    this.partnerProfileImageUrl,
  });

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      partnerId: json['partnerId'] as int,
      partnerName: json['partnerName'] as String? ?? '',
      partnerEmail: json['partnerEmail'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTimestamp: json['lastMessageTimestamp'] != null &&
              (json['lastMessageTimestamp'] as String).isNotEmpty
          ? DateTime.tryParse(json['lastMessageTimestamp'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      partnerProfileImageUrl: json['partnerProfileImageUrl'] as String?,
    );
  }
}
