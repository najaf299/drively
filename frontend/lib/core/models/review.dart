import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String? reviewedUserId;
  final String? carId;
  final String reviewType; // 'host' or 'guest' or 'car'
  final double rating;
  final String? comment;
  final List<String>? photos;
  final List<double>? subRatings; // [cleanliness, communication, accuracy, etc.]
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relationships
  final String? reviewerName;
  final String? reviewerAvatar;
  final String? reviewedUserName;
  final String? reviewedUserAvatar;

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    this.reviewedUserId,
    this.carId,
    required this.reviewType,
    required this.rating,
    this.comment,
    this.photos,
    this.subRatings,
    required this.createdAt,
    required this.updatedAt,
    this.reviewerName,
    this.reviewerAvatar,
    this.reviewedUserName,
    this.reviewedUserAvatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  bool get isHostReview => reviewType == 'host';
  bool get isGuestReview => reviewType == 'guest';
  bool get isCarReview => reviewType == 'car';
}

@JsonSerializable()
class ReviewSubmission {
  final String bookingId;
  final String reviewType;
  final double rating;
  final String? comment;
  final List<String>? photos;
  final List<double>? subRatings;

  ReviewSubmission({
    required this.bookingId,
    required this.reviewType,
    required this.rating,
    this.comment,
    this.photos,
    this.subRatings,
  });

  factory ReviewSubmission.fromJson(Map<String, dynamic> json) => _$ReviewSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewSubmissionToJson(this);
}
