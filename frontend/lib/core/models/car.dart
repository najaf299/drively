import 'package:json_annotation/json_annotation.dart';

part 'car.g.dart';

@JsonSerializable()
class Car {
  final String id;
  final String hostId;
  final String make;
  final String model;
  final int year;
  final String? trim;
  final String plateNumber;
  final String transmission;
  final String fuelType;
  final int seats;
  final int doors;
  final double dailyPrice;
  final double weeklyDiscountPct;
  final double monthlyDiscountPct;
  final bool dynamicPricingEnabled;
  final double? suggestedPrice;
  final String? description;
  final List<String> features;
  final double lat;
  final double lng;
  final String address;
  final String city;
  final String country;
  final int? mileageLimitPerDay;
  final double? excessMileageFee;
  final String fuelPolicy;
  final String deliveryType;
  final double? deliveryFee;
  final String cancellationPolicy;
  final List<String> photos;
  final String status;
  final double? rating;
  final int? totalTrips;
  final int? totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.hostId,
    required this.make,
    required this.model,
    required this.year,
    this.trim,
    required this.plateNumber,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.doors,
    required this.dailyPrice,
    required this.weeklyDiscountPct,
    required this.monthlyDiscountPct,
    required this.dynamicPricingEnabled,
    this.suggestedPrice,
    this.description,
    required this.features,
    required this.lat,
    required this.lng,
    required this.address,
    required this.city,
    required this.country,
    this.mileageLimitPerDay,
    this.excessMileageFee,
    required this.fuelPolicy,
    required this.deliveryType,
    this.deliveryFee,
    required this.cancellationPolicy,
    required this.photos,
    required this.status,
    this.rating,
    this.totalTrips,
    this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) => _$CarFromJson(json);
  Map<String, dynamic> toJson() => _$CarToJson(this);

  String get displayName => '$year $make $model';
  bool get isActive => status == 'active';
  bool get isAutomatic => transmission == 'automatic';
  bool get hasUnlimitedMileage => mileageLimitPerDay == null;
}
