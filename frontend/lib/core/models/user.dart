import '../utils/json_utils.dart';
import 'wallet.dart';

/// A full user/account (matches `UserResource` and the raw model returned by
/// the auth endpoints).
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // customer | host | admin
  final String kycStatus; // none | pending | in_review | approved | rejected
  final String? avatarUrl;
  final String? bio;
  final double averageRating;
  final int totalTrips;
  final String preferredLanguage;
  final String preferredCurrency;
  final String preferredUnits;
  final Map<String, dynamic>? notificationSettings;
  final bool isSuspended;
  final String? suspensionReason;
  final String? referralCode;
  final DateTime? phoneVerifiedAt;
  final DateTime? emailVerifiedAt;
  final Wallet? wallet;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.kycStatus,
    this.avatarUrl,
    this.bio,
    this.averageRating = 0,
    this.totalTrips = 0,
    this.preferredLanguage = 'en',
    this.preferredCurrency = 'USD',
    this.preferredUnits = 'km',
    this.notificationSettings,
    this.isSuspended = false,
    this.suspensionReason,
    this.referralCode,
    this.phoneVerifiedAt,
    this.emailVerifiedAt,
    this.wallet,
    this.createdAt,
  });

  bool get isCustomer => role == 'customer';
  bool get isHost => role == 'host';
  bool get isAdmin => role == 'admin';
  bool get isKycApproved => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending' || kycStatus == 'in_review';
  bool get isPhoneVerified => phoneVerifiedAt != null;
  bool get isEmailVerified => emailVerifiedAt != null;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asString(json['id']),
        name: asString(json['name']),
        email: asString(json['email']),
        phone: asStringOrNull(json['phone']),
        role: asString(json['role'], fallback: 'customer'),
        kycStatus: asString(json['kyc_status'], fallback: 'none'),
        avatarUrl: asStringOrNull(json['avatar_url']),
        bio: asStringOrNull(json['bio']),
        averageRating: asDouble(json['average_rating']),
        totalTrips: asInt(json['total_trips']),
        preferredLanguage: asString(json['preferred_language'], fallback: 'en'),
        preferredCurrency: asString(json['preferred_currency'], fallback: 'USD'),
        preferredUnits: asString(json['preferred_units'], fallback: 'km'),
        notificationSettings: asMap(json['notification_settings']),
        isSuspended: asBool(json['is_suspended']),
        suspensionReason: asStringOrNull(json['suspension_reason']),
        referralCode: asStringOrNull(json['referral_code']),
        phoneVerifiedAt: asDateTime(json['phone_verified_at']),
        emailVerifiedAt: asDateTime(json['email_verified_at']),
        wallet: json['wallet'] is Map
            ? Wallet.fromJson(Map<String, dynamic>.from(json['wallet']))
            : null,
        createdAt: asDateTime(json['created_at']),
      );
}

/// Lightweight user reference embedded in other resources
/// (matches `UserSummaryResource`).
class UserSummary {
  final String id;
  final String name;
  final String? avatarUrl;
  final double? averageRating;
  final int? totalTrips;
  final String? phone;

  const UserSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.averageRating,
    this.totalTrips,
    this.phone,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        id: asString(json['id']),
        name: asString(json['name']),
        avatarUrl: asStringOrNull(json['avatar_url']),
        averageRating: asDoubleOrNull(json['average_rating']),
        totalTrips: asIntOrNull(json['total_trips']),
        phone: asStringOrNull(json['phone']),
      );
}

/// Result of a successful login/registration: a user plus a Sanctum token.
class AuthResult {
  final User user;
  final String token;

  const AuthResult({required this.user, required this.token});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: User.fromJson(Map<String, dynamic>.from(json['user'])),
        token: asString(json['token']),
      );
}

/// Result of OTP verification. Existing users receive a [user]/[token]; brand
/// new numbers receive `isNew = true` and must complete registration.
class OtpVerifyResult {
  final bool isNew;
  final User? user;
  final String? token;

  const OtpVerifyResult({required this.isNew, this.user, this.token});

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) => OtpVerifyResult(
        isNew: asBool(json['is_new']),
        user: json['user'] is Map
            ? User.fromJson(Map<String, dynamic>.from(json['user']))
            : null,
        token: asStringOrNull(json['token']),
      );
}
