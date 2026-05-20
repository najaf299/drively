import '../utils/json_utils.dart';
import 'booking.dart';

/// A single host earning for a completed booking (matches `EarningResource`).
class Earning {
  final String id;
  final String bookingId;
  final double grossAmount;
  final double platformCommission;
  final double insuranceFee;
  final double netAmount;
  final String status; // pending | paid
  final DateTime? paidAt;
  final Booking? booking;
  final DateTime? createdAt;

  const Earning({
    required this.id,
    required this.bookingId,
    required this.grossAmount,
    required this.platformCommission,
    required this.insuranceFee,
    required this.netAmount,
    required this.status,
    this.paidAt,
    this.booking,
    this.createdAt,
  });

  bool get isPaid => status == 'paid';

  factory Earning.fromJson(Map<String, dynamic> json) => Earning(
        id: asString(json['id']),
        bookingId: asString(json['booking_id']),
        grossAmount: asDouble(json['gross_amount']),
        platformCommission: asDouble(json['platform_commission']),
        insuranceFee: asDouble(json['insurance_fee']),
        netAmount: asDouble(json['net_amount']),
        status: asString(json['status'], fallback: 'pending'),
        paidAt: asDateTime(json['paid_at']),
        booking: json['booking'] is Map
            ? Booking.fromJson(Map<String, dynamic>.from(json['booking']))
            : null,
        createdAt: asDateTime(json['created_at']),
      );
}

/// Aggregated earnings summary for `GET /host/earnings`. The backend's exact
/// keys may vary, so values are read defensively with sensible fallbacks.
class EarningsSummary {
  final double total;
  final double net;
  final double gross;
  final double commission;
  final int tripsCount;
  final String period;
  final Map<String, dynamic> raw;

  const EarningsSummary({
    this.total = 0,
    this.net = 0,
    this.gross = 0,
    this.commission = 0,
    this.tripsCount = 0,
    this.period = 'month',
    this.raw = const {},
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) =>
      EarningsSummary(
        total: asDouble(json['total'] ?? json['total_earnings'] ?? json['net']),
        net: asDouble(json['net'] ?? json['net_amount'] ?? json['total']),
        gross: asDouble(json['gross'] ?? json['gross_amount']),
        commission: asDouble(json['commission'] ?? json['platform_commission']),
        tripsCount:
            asInt(json['trips_count'] ?? json['trips'] ?? json['count']),
        period: asString(json['period'], fallback: 'month'),
        raw: json,
      );
}
