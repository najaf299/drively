import '../utils/json_utils.dart';

/// An in-app notification (Laravel `DatabaseNotification` shape:
/// `{ id, type, data, read_at, created_at }`). The display title/body and any
/// deep-link live inside the free-form [data] payload.
class AppNotification {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.data = const {},
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  String get title => asString(
        data['title'] ?? data['heading'],
        fallback: 'Notification',
      );

  String get body =>
      asString(data['body'] ?? data['message'] ?? data['text']);

  /// Optional in-app deep link, e.g. `/trip/123`.
  String? get deepLink => asStringOrNull(data['url'] ?? data['deep_link']);

  /// Short category derived from [type] or [data], used to pick an icon/colour.
  String get category {
    final t = (data['category'] ?? type).toString().toLowerCase();
    if (t.contains('booking')) return 'booking';
    if (t.contains('payment') || t.contains('payout') || t.contains('wallet')) {
      return 'payment';
    }
    if (t.contains('trip') || t.contains('alert')) return 'alert';
    if (t.contains('promo')) return 'promo';
    if (t.contains('message') || t.contains('chat')) return 'message';
    return 'system';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: asString(json['id']),
        type: asString(json['type']),
        data: asMap(json['data']) ?? const {},
        readAt: asDateTime(json['read_at']),
        createdAt: asDateTime(json['created_at']),
      );
}
