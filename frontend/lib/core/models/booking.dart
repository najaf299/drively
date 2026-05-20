import '../utils/json_utils.dart';
import 'car.dart';
import 'review.dart';
import 'trip.dart';
import 'user.dart';

/// Price breakdown for a booking (matches `BookingResource.pricing` and the
/// standalone `POST /customer/bookings/pricing` response).
class BookingPricing {
  final double dailyRate;
  final int totalDays;
  final double subtotal;
  final double addonsTotal;
  final double serviceFee;
  final double tax;
  final double discount;
  final double totalAmount;

  const BookingPricing({
    this.dailyRate = 0,
    this.totalDays = 0,
    this.subtotal = 0,
    this.addonsTotal = 0,
    this.serviceFee = 0,
    this.tax = 0,
    this.discount = 0,
    this.totalAmount = 0,
  });

  factory BookingPricing.fromJson(Map<String, dynamic> json) => BookingPricing(
        dailyRate: asDouble(json['daily_rate']),
        totalDays: asInt(json['total_days']),
        subtotal: asDouble(json['subtotal']),
        addonsTotal: asDouble(json['addons_total']),
        serviceFee: asDouble(json['service_fee']),
        tax: asDouble(json['tax']),
        discount: asDouble(json['discount']),
        // Tolerate alternative keys from the pricing-preview endpoint.
        totalAmount: asDouble(
          json['total_amount'] ?? json['total'] ?? json['grand_total'],
        ),
      );
}

/// A rental booking (matches `BookingResource`).
class Booking {
  final String id;
  final String reference;
  final String carId;
  final String customerId;
  final String
      status; // pending | confirmed | active | completed | cancelled | declined
  final String bookingType; // instant | request
  final DateTime? pickupAt;
  final DateTime? returnAt;
  final String? pickupAddress;
  final BookingPricing pricing;
  final List<dynamic>? addons;
  final String? cancellationReason;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? hostResponseDeadline;
  final Car? car;
  final UserSummary? customer;
  final Map<String, dynamic>? payment;
  final Trip? trip;
  final List<Review> reviews;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.reference,
    required this.carId,
    required this.customerId,
    required this.status,
    this.bookingType = 'instant',
    this.pickupAt,
    this.returnAt,
    this.pickupAddress,
    this.pricing = const BookingPricing(),
    this.addons,
    this.cancellationReason,
    this.confirmedAt,
    this.cancelledAt,
    this.hostResponseDeadline,
    this.car,
    this.customer,
    this.payment,
    this.trip,
    this.reviews = const [],
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'declined';
  bool get canCancel => isPending || isConfirmed;
  bool get canReview => isCompleted && reviews.isEmpty;
  bool get isPaid => payment?['status'] == 'succeeded';

  int get totalDays {
    if (pricing.totalDays > 0) return pricing.totalDays;
    if (pickupAt != null && returnAt != null) {
      return returnAt!.difference(pickupAt!).inDays.clamp(1, 365);
    }
    return 0;
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: asString(json['id']),
        reference: asString(json['reference']),
        carId: asString(json['car_id']),
        customerId: asString(json['customer_id']),
        status: asString(json['status'], fallback: 'pending'),
        bookingType: asString(json['booking_type'], fallback: 'instant'),
        pickupAt: asDateTime(json['pickup_at']),
        returnAt: asDateTime(json['return_at']),
        pickupAddress: asStringOrNull(json['pickup_address']),
        pricing: json['pricing'] is Map
            ? BookingPricing.fromJson(
                Map<String, dynamic>.from(json['pricing']))
            : const BookingPricing(),
        addons: json['addons'] is List ? json['addons'] as List : null,
        cancellationReason: asStringOrNull(json['cancellation_reason']),
        confirmedAt: asDateTime(json['confirmed_at']),
        cancelledAt: asDateTime(json['cancelled_at']),
        hostResponseDeadline: asDateTime(json['host_response_deadline']),
        car: json['car'] is Map
            ? Car.fromJson(Map<String, dynamic>.from(json['car']))
            : null,
        customer: json['customer'] is Map
            ? UserSummary.fromJson(Map<String, dynamic>.from(json['customer']))
            : null,
        payment: asMap(json['payment']),
        trip: json['trip'] is Map
            ? Trip.fromJson(Map<String, dynamic>.from(json['trip']))
            : null,
        reviews: asList(json['reviews'], Review.fromJson),
        createdAt: asDateTime(json['created_at']),
      );
}
