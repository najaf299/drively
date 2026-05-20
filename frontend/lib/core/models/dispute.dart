import '../utils/json_utils.dart';
import 'user.dart';

/// A dispute raised against a booking (matches `DisputeResource`).
class Dispute {
  final String id;
  final String bookingId;
  final String reporterId;
  final String type; // damage | late_return | no_show | fraud | other
  final String description;
  final List<String> evidenceUrls;
  final String status; // open | investigating | resolved | escalated | ...
  final String? resolution;
  final double? refundAmount;
  final DateTime? resolvedAt;
  final UserSummary? reporter;
  final UserSummary? resolver;
  final Map<String, dynamic>? booking;
  final DateTime? createdAt;

  const Dispute({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.type,
    required this.description,
    this.evidenceUrls = const [],
    required this.status,
    this.resolution,
    this.refundAmount,
    this.resolvedAt,
    this.reporter,
    this.resolver,
    this.booking,
    this.createdAt,
  });

  bool get isResolved => status == 'resolved';
  bool get isOpen => status == 'open' || status == 'investigating';

  factory Dispute.fromJson(Map<String, dynamic> json) => Dispute(
        id: asString(json['id']),
        bookingId: asString(json['booking_id']),
        reporterId: asString(json['reporter_id']),
        type: asString(json['type'], fallback: 'other'),
        description: asString(json['description']),
        evidenceUrls: asStringList(json['evidence_urls']),
        status: asString(json['status'], fallback: 'open'),
        resolution: asStringOrNull(json['resolution']),
        refundAmount: asDoubleOrNull(json['refund_amount']),
        resolvedAt: asDateTime(json['resolved_at']),
        reporter: json['reporter'] is Map
            ? UserSummary.fromJson(Map<String, dynamic>.from(json['reporter']))
            : null,
        resolver: json['resolver'] is Map
            ? UserSummary.fromJson(Map<String, dynamic>.from(json['resolver']))
            : null,
        booking: asMap(json['booking']),
        createdAt: asDateTime(json['created_at']),
      );
}
