import '../utils/json_utils.dart';
import 'user.dart';

/// A single chat message (matches `ChatMessageResource` and the raw model
/// embedded as a thread's `latest_message`).
class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final String type; // text | image
  final String? imageUrl;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final UserSummary? sender;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.imageUrl,
    this.readAt,
    this.deliveredAt,
    this.sender,
    this.createdAt,
  });

  bool get isImage => type == 'image';
  bool get isRead => readAt != null;
  bool get isDelivered => deliveredAt != null;
  bool isFromMe(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: asString(json['id']),
        threadId: asString(json['thread_id']),
        senderId: asString(json['sender_id']),
        content: asString(json['content']),
        type: asString(json['type'], fallback: 'text'),
        imageUrl: asStringOrNull(json['image_url']),
        readAt: asDateTime(json['read_at']),
        deliveredAt: asDateTime(json['delivered_at']),
        sender: json['sender'] is Map
            ? UserSummary.fromJson(Map<String, dynamic>.from(json['sender']))
            : null,
        createdAt: asDateTime(json['created_at']),
      );
}

/// A 1:1 conversation between two users (matches both the raw `ChatThread`
/// model returned by the list endpoint and `ChatThreadResource`).
class ChatThread {
  final String id;
  final String? bookingId;
  final int unreadCount;
  final UserSummary? participantOne;
  final UserSummary? participantTwo;
  final UserSummary? _resolvedOther; // from `other_participant`
  final ChatMessage? latestMessage;
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    this.bookingId,
    this.unreadCount = 0,
    this.participantOne,
    this.participantTwo,
    UserSummary? resolvedOther,
    this.latestMessage,
    this.updatedAt,
  }) : _resolvedOther = resolvedOther;

  /// The participant who is *not* [currentUserId].
  UserSummary? otherParticipant(String currentUserId) {
    if (_resolvedOther != null) return _resolvedOther;
    if (participantOne != null && participantOne!.id == currentUserId) {
      return participantTwo;
    }
    if (participantTwo != null && participantTwo!.id == currentUserId) {
      return participantOne;
    }
    return participantOne ?? participantTwo;
  }

  bool get hasUnread => unreadCount > 0;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: asString(json['id']),
        bookingId: asStringOrNull(json['booking_id']),
        unreadCount: asInt(json['unread_count']),
        participantOne: json['participant_one'] is Map
            ? UserSummary.fromJson(
                Map<String, dynamic>.from(json['participant_one']))
            : null,
        participantTwo: json['participant_two'] is Map
            ? UserSummary.fromJson(
                Map<String, dynamic>.from(json['participant_two']))
            : null,
        resolvedOther: json['other_participant'] is Map
            ? UserSummary.fromJson(
                Map<String, dynamic>.from(json['other_participant']))
            : null,
        latestMessage: json['latest_message'] is Map
            ? ChatMessage.fromJson(
                Map<String, dynamic>.from(json['latest_message']))
            : null,
        updatedAt: asDateTime(json['updated_at']),
      );
}
