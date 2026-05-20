import '../utils/json_utils.dart';

/// A promotional discount code (matches `PromoCodeResource`).
class PromoCode {
  final String id;
  final String code;
  final String type; // percentage | fixed
  final double value;
  final double? maxDiscount;
  final double? minBookingAmount;
  final int? maxUses;
  final int? maxUsesPerUser;
  final int timesUsed;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;

  const PromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minBookingAmount,
    this.maxUses,
    this.maxUsesPerUser,
    this.timesUsed = 0,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
  });

  bool get isPercentage => type == 'percentage';

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
        id: asString(json['id']),
        code: asString(json['code']),
        type: asString(json['type'], fallback: 'percentage'),
        value: asDouble(json['value']),
        maxDiscount: asDoubleOrNull(json['max_discount']),
        minBookingAmount: asDoubleOrNull(json['min_booking_amount']),
        maxUses: asIntOrNull(json['max_uses']),
        maxUsesPerUser: asIntOrNull(json['max_uses_per_user']),
        timesUsed: asInt(json['times_used']),
        validFrom: asDateTime(json['valid_from']),
        validUntil: asDateTime(json['valid_until']),
        isActive: asBool(json['is_active'], fallback: true),
      );
}
