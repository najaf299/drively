import '../utils/json_utils.dart';
import 'user.dart';

/// A single car photo (matches `CarPhotoResource`).
class CarPhoto {
  final String id;
  final String url;
  final int order;
  final bool isCover;

  const CarPhoto({
    required this.id,
    required this.url,
    this.order = 0,
    this.isCover = false,
  });

  factory CarPhoto.fromJson(Map<String, dynamic> json) => CarPhoto(
        id: asString(json['id']),
        url: asString(json['url']),
        order: asInt(json['order']),
        isCover: asBool(json['is_cover']),
      );
}

/// A car listing (matches `CarResource`, whose `location` is a nested object).
class Car {
  final String id;
  final String hostId;
  final String make;
  final String model;
  final int year;
  final String? trim;
  final String? plateNumber;
  final String transmission; // automatic | manual
  final String fuelType; // petrol | diesel | electric | hybrid
  final int seats;
  final int doors;
  final double dailyPrice;
  final double weeklyDiscountPct;
  final double monthlyDiscountPct;
  final bool dynamicPricingEnabled;
  final bool instantBooking;
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
  final bool smokingAllowed;
  final bool petsAllowed;
  final String status; // draft | active | paused | pending_approval | ...
  final double averageRating;
  final int totalReviews;
  final List<CarPhoto> photos;
  final UserSummary? host;
  final double? distance; // km, only present on nearby searches
  final DateTime? createdAt;

  const Car({
    required this.id,
    required this.hostId,
    required this.make,
    required this.model,
    required this.year,
    this.trim,
    this.plateNumber,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.doors,
    required this.dailyPrice,
    this.weeklyDiscountPct = 0,
    this.monthlyDiscountPct = 0,
    this.dynamicPricingEnabled = false,
    this.instantBooking = true,
    this.description,
    this.features = const [],
    required this.lat,
    required this.lng,
    required this.address,
    required this.city,
    required this.country,
    this.mileageLimitPerDay,
    this.excessMileageFee,
    required this.fuelPolicy,
    this.smokingAllowed = false,
    this.petsAllowed = false,
    required this.status,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.photos = const [],
    this.host,
    this.distance,
    this.createdAt,
  });

  String get displayName => '$make $model';
  String get displayNameWithYear => '$year $make $model';
  bool get isActive => status == 'active';
  bool get isAutomatic => transmission == 'automatic';
  bool get hasUnlimitedMileage => mileageLimitPerDay == null;

  /// Best photo to show on a card: the cover, else the first, else null.
  String? get coverPhotoUrl {
    if (photos.isEmpty) return null;
    final cover = photos.where((p) => p.isCover);
    if (cover.isNotEmpty) return cover.first.url;
    return photos.first.url;
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    final location = asMap(json['location']) ?? const {};
    return Car(
      id: asString(json['id']),
      hostId: asString(json['host_id']),
      make: asString(json['make']),
      model: asString(json['model']),
      year: asInt(json['year']),
      trim: asStringOrNull(json['trim']),
      plateNumber: asStringOrNull(json['plate_number']),
      transmission: asString(json['transmission'], fallback: 'automatic'),
      fuelType: asString(json['fuel_type'], fallback: 'petrol'),
      seats: asInt(json['seats'], fallback: 4),
      doors: asInt(json['doors'], fallback: 4),
      dailyPrice: asDouble(json['daily_price']),
      weeklyDiscountPct: asDouble(json['weekly_discount_pct']),
      monthlyDiscountPct: asDouble(json['monthly_discount_pct']),
      dynamicPricingEnabled: asBool(json['dynamic_pricing_enabled']),
      instantBooking: asBool(json['instant_booking'], fallback: true),
      description: asStringOrNull(json['description']),
      features: asStringList(json['features']),
      lat: asDouble(location['lat'] ?? json['lat']),
      lng: asDouble(location['lng'] ?? json['lng']),
      address: asString(location['address'] ?? json['address']),
      city: asString(location['city'] ?? json['city']),
      country: asString(location['country'] ?? json['country']),
      mileageLimitPerDay: asIntOrNull(json['mileage_limit_per_day']),
      excessMileageFee: asDoubleOrNull(json['excess_mileage_fee']),
      fuelPolicy: asString(json['fuel_policy'], fallback: 'full_to_full'),
      smokingAllowed: asBool(json['smoking_allowed']),
      petsAllowed: asBool(json['pets_allowed']),
      status: asString(json['status'], fallback: 'active'),
      averageRating: asDouble(json['average_rating']),
      totalReviews: asInt(json['total_reviews']),
      photos: asList(json['photos'], CarPhoto.fromJson),
      host: json['host'] is Map
          ? UserSummary.fromJson(Map<String, dynamic>.from(json['host']))
          : null,
      distance: asDoubleOrNull(json['distance']),
      createdAt: asDateTime(json['created_at']),
    );
  }
}
