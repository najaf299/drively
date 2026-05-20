import 'package:json_annotation/json_annotation.dart';

part 'promo_code.g.dart';

@JsonSerializable()
class PromoCode {
  final String id;
  final String code;
  final String? description;
  final String type; // 'percentage', 'fixed'
  final double value;
  final double? minimumOrder;
  final double? maximumDiscount;
  final int? usageLimit;
  final int usageCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final List<String>? applicableUserIds;
  final List<String>? applicableCarIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromoCode({
    required this.id,
    required this.code,
    this.description,
    required this.type,
    required this.value,
    this.minimumOrder,
    this.maximumDiscount,
    this.usageLimit,
    required this.usageCount,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    this.applicableUserIds,
    this.applicableCarIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) => _$PromoCodeFromJson(json);
  Map<String, dynamic> toJson() => _$PromoCodeToJson(this);

  bool get isPercentage => type == 'percentage';
  bool get isFixed => type == 'fixed';
  bool get isValid => isActive && 
      (validFrom == null || DateTime.now().isAfter(validFrom!)) &&
      (validUntil == null || DateTime.now().isBefore(validUntil!));
  bool get isExpired => validUntil != null && DateTime.now().isAfter(validUntil!);
  bool get usageLimitReached => usageLimit != null && usageCount >= usageLimit!;
}
