import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class NotificationItem {
  final String id;
  final String userId;
  final String type; // 'booking', 'trip', 'chat', 'payment', 'system'
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => _$NotificationItemFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationItemToJson(this);

  bool get isBooking => type == 'booking';
  bool get isTrip => type == 'trip';
  bool get isChat => type == 'chat';
  bool get isPayment => type == 'payment';
  bool get isSystem => type == 'system';
}

@JsonSerializable()
class DeviceRegistration {
  final String token;
  final String platform; // 'ios', 'android'
  final String? appId;
  final String? deviceId;

  DeviceRegistration({
    required this.token,
    required this.platform,
    this.appId,
    this.deviceId,
  });

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) => _$DeviceRegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceRegistrationToJson(this);
}
