import '../utils/json_utils.dart';
import 'user.dart';

/// A review left after a completed booking (matches `ReviewResource`).
class Review {
  final String id;
  final String bookingId;
  final String type; // car | host | customer
  final int rating;
  final int? cleanlinessRating;
  final int? communicationRating;
  final int? accuracyRating;
  final int? pickupRating;
  final String? comment;
  final List<String> tags;
  final List<String> photoUrls;
  final bool isPublic;
  final UserSummary? reviewer;
  final UserSummary? reviewee;
  final Map<String, dynamic>? car;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.rating,
    this.cleanlinessRating,
    this.communicationRating,
    this.accuracyRating,
    this.pickupRating,
    this.comment,
    this.tags = const [],
    this.photoUrls = const [],
    this.isPublic = true,
    this.reviewer,
    this.reviewee,
    this.car,
    this.createdAt,
  });

  bool get hasPhotos => photoUrls.isNotEmpty;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: asString(json['id']),
        bookingId: asString(json['booking_id']),
        type: asString(json['type'], fallback: 'car'),
        rating: asInt(json['rating']),
        cleanlinessRating: asIntOrNull(json['cleanliness_rating']),
        communicationRating: asIntOrNull(json['communication_rating']),
        accuracyRating: asIntOrNull(json['accuracy_rating']),
        pickupRating: asIntOrNull(json['pickup_rating']),
        comment: asStringOrNull(json['comment']),
        tags: asStringList(json['tags']),
        photoUrls: asStringList(json['photo_urls']),
        isPublic: asBool(json['is_public'], fallback: true),
        reviewer: json['reviewer'] is Map
            ? UserSummary.fromJson(Map<String, dynamic>.from(json['reviewer']))
            : null,
        reviewee: json['reviewee'] is Map
            ? UserSummary.fromJson(Map<String, dynamic>.from(json['reviewee']))
            : null,
        car: asMap(json['car']),
        createdAt: asDateTime(json['created_at']),
      );
}
