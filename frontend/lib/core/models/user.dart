import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? phoneVerifiedAt;
  final DateTime? emailVerifiedAt;
  final String? avatarUrl;
  final String role;
  final String kycStatus;
  final String? googleId;
  final String? appleId;
  final double averageRating;
  final int totalTrips;
  final String preferredLanguage;
  final String preferredCurrency;
  final String preferredUnits;
  final Map<String, bool>? notificationSettings;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.phoneVerifiedAt,
    this.emailVerifiedAt,
    this.avatarUrl,
    required this.role,
    required this.kycStatus,
    this.googleId,
    this.appleId,
    required this.averageRating,
    required this.totalTrips,
    required this.preferredLanguage,
    required this.preferredCurrency,
    required this.preferredUnits,
    this.notificationSettings,
    required this.isSuspended,
    this.suspensionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isCustomer => role == 'customer';
  bool get isHost => role == 'host';
  bool get isAdmin => role == 'admin';
  bool get isKycVerified => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending' || kycStatus == 'in_review';
}

@JsonSerializable()
class LoginResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final String? tokenType;

  LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
