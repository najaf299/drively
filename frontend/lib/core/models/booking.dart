import 'package:json_annotation/json_annotation.dart';
import 'car.dart';
import 'user.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final String id;
  final String customerId;
  final String carId;
  final String hostId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final String? paymentIntentId;
  final String? paymentStatus;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final double? refundAmount;
  final String? promoCodeId;
  final double? discountAmount;
  final List<String> specialRequests;
  final String? tripId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final Car? car;
  final User? customer;
  final User? host;

  Booking({
    required this.id,
    required this.customerId,
    required this.carId,
    required this.hostId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.paymentIntentId,
    this.paymentStatus,
    this.paidAt,
    this.cancelledAt,
    this.cancellationReason,
    this.refundAmount,
    this.promoCodeId,
    this.discountAmount,
    required this.specialRequests,
    this.tripId,
    required this.createdAt,
    required this.updatedAt,
    this.car,
    this.customer,
    this.host,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => paymentStatus == 'paid';
  int get durationDays => endDate.difference(startDate).inDays + 1;
}

@JsonSerializable()
class BookingPricing {
  final double dailyRate;
  final double durationDays;
  final double basePrice;
  final double weeklyDiscount;
  final double monthlyDiscount;
  final double deliveryFee;
  final double insuranceFee;
  final double serviceFee;
  final double taxes;
  final double totalPrice;
  final double? promoDiscount;
  final double? discountedTotal;

  BookingPricing({
    required this.dailyRate,
    required this.durationDays,
    required this.basePrice,
    required this.weeklyDiscount,
    required this.monthlyDiscount,
    required this.deliveryFee,
    required this.insuranceFee,
    required this.serviceFee,
    required this.taxes,
    required this.totalPrice,
    this.promoDiscount,
    this.discountedTotal,
  });

  factory BookingPricing.fromJson(Map<String, dynamic> json) => _$BookingPricingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingPricingToJson(this);
}
