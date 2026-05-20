import 'package:json_annotation/json_annotation.dart';

part 'chat.g.dart';

@JsonSerializable()
class ChatThread {
  final String id;
  final String? bookingId;
  final List<String> participants;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final Map<String, dynamic>? participantsInfo;
  final Booking? booking;

  ChatThread({
    required this.id,
    this.bookingId,
    required this.participants,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.participantsInfo,
    this.booking,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) => _$ChatThreadFromJson(json);
  Map<String, dynamic> toJson() => _$ChatThreadToJson(this);

  String? get otherParticipantName {
    if (participantsInfo != null && participantsInfo!.isNotEmpty) {
      final firstKey = participantsInfo!.keys.first;
      return participantsInfo![firstKey]?['name'];
    }
    return null;
  }
}

@JsonSerializable()
class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final String messageType; // 'text', 'image', 'location', 'system'
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final String? senderName;
  final String? senderAvatar;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.metadata,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.senderAvatar,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  bool get isFromMe => senderId != null; // Will be set by auth context
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isSystem => messageType == 'system';
}

@JsonSerializable()
class SendMessageRequest {
  final String threadId;
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;

  SendMessageRequest({
    required this.threadId,
    required this.content,
    this.messageType = 'text',
    this.metadata,
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) => _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}
