import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/review.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref.read(dioProvider));
});

/// Review submission + history (`/customer/bookings/{id}/review`, `/customer/reviews`).
class ReviewService {
  final Dio _dio;
  ReviewService(this._dio);

  Future<Review> submit(
    String bookingId, {
    required int rating,
    int? cleanliness,
    int? communication,
    int? accuracy,
    int? pickup,
    String? comment,
    List<String>? tags,
    List<String>? photoUrls,
    bool isPublic = true,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.bookingReview(bookingId), data: {
        'rating': rating,
        if (cleanliness != null) 'cleanliness_rating': cleanliness,
        if (communication != null) 'communication_rating': communication,
        if (accuracy != null) 'accuracy_rating': accuracy,
        if (pickup != null) 'pickup_rating': pickup,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (tags != null) 'tags': tags,
        if (photoUrls != null) 'photo_urls': photoUrls,
        'is_public': isPublic,
      });
      return Review.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Paginated<Review>> myReviews({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.myReviews,
        queryParameters: {'page': page},
      );
      return Paginated<Review>.from(ApiResponse.data(res.data), Review.fromJson);
    } catch (e) {
      throw mapError(e);
    }
  }
}
