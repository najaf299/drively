import 'package:json_annotation/json_annotation.dart';
import 'booking.dart';

part 'trip.g.dart';

@JsonSerializable()
class Trip {
  final String id;
  final String bookingId;
  final String customerId;
  final String hostId;
  final String carId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? scheduledEndAt;
  final double? startOdometer;
  final double? endOdometer;
  final int? mileageDriven;
  final double? extraMileageFee;
  final List<String>? startPhotos;
  final List<String>? endPhotos;
  final String? startCondition;
  final String? endCondition;
  final String? pickupNotes;
  final String? returnNotes;
  final Map<String, dynamic>? currentLocation;
  final DateTime? locationUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final Booking? booking;

  Trip({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.hostId,
    required this.carId,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.scheduledEndAt,
    this.startOdometer,
    this.endOdometer,
    this.mileageDriven,
    this.extraMileageFee,
    this.startPhotos,
    this.endPhotos,
    this.startCondition,
    this.endCondition,
    this.pickupNotes,
    this.returnNotes,
    this.currentLocation,
    this.locationUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.booking,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isExtended => status == 'extended';
  bool get hasStarted => startedAt != null;
  bool get hasEnded => endedAt != null;
  Duration? get duration {
    if (startedAt != null && endedAt != null) {
      return endedAt!.difference(startedAt!);
    }
    return null;
  }
}

@JsonSerializable()
class TripLocationUpdate {
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  TripLocationUpdate({
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory TripLocationUpdate.fromJson(Map<String, dynamic> json) => _$TripLocationUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$TripLocationUpdateToJson(this);
}

@JsonSerializable()
class TripExtensionRequest {
  final DateTime newEndTime;
  final String reason;
  final double additionalCost;

  TripExtensionRequest({
    required this.newEndTime,
    required this.reason,
    required this.additionalCost,
  });

  factory TripExtensionRequest.fromJson(Map<String, dynamic> json) => _$TripExtensionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TripExtensionRequestToJson(this);
}
