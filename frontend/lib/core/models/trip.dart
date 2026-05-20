import '../utils/json_utils.dart';
import 'booking.dart';

/// An in-progress / completed trip for a booking (matches `TripResource`).
class Trip {
  final String id;
  final String bookingId;
  final String status; // pending | in_progress | overdue | completed
  final int? mileageStart;
  final int? mileageEnd;
  final int? totalMileage;
  final int? fuelLevelStart;
  final int? fuelLevelEnd;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime? locationUpdatedAt;
  final bool extended;
  final int extensionDays;
  final bool isOverdue;
  final Booking? booking;
  final DateTime? createdAt;

  const Trip({
    required this.id,
    required this.bookingId,
    required this.status,
    this.mileageStart,
    this.mileageEnd,
    this.totalMileage,
    this.fuelLevelStart,
    this.fuelLevelEnd,
    this.startedAt,
    this.endedAt,
    this.lastKnownLat,
    this.lastKnownLng,
    this.locationUpdatedAt,
    this.extended = false,
    this.extensionDays = 0,
    this.isOverdue = false,
    this.booking,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get hasStarted => startedAt != null;
  bool get hasLocation => lastKnownLat != null && lastKnownLng != null;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final loc = asMap(json['last_known_location']) ?? const {};
    return Trip(
      id: asString(json['id']),
      bookingId: asString(json['booking_id']),
      status: asString(json['status'], fallback: 'pending'),
      mileageStart: asIntOrNull(json['mileage_start']),
      mileageEnd: asIntOrNull(json['mileage_end']),
      totalMileage: asIntOrNull(json['total_mileage']),
      fuelLevelStart: asIntOrNull(json['fuel_level_start']),
      fuelLevelEnd: asIntOrNull(json['fuel_level_end']),
      startedAt: asDateTime(json['started_at']),
      endedAt: asDateTime(json['ended_at']),
      lastKnownLat: asDoubleOrNull(loc['lat']),
      lastKnownLng: asDoubleOrNull(loc['lng']),
      locationUpdatedAt: asDateTime(loc['updated_at']),
      extended: asBool(json['extended']),
      extensionDays: asInt(json['extension_days']),
      isOverdue: asBool(json['is_overdue']),
      booking: json['booking'] is Map
          ? Booking.fromJson(Map<String, dynamic>.from(json['booking']))
          : null,
      createdAt: asDateTime(json['created_at']),
    );
  }
}
