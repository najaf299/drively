import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/review.dart';
import '../../../../core/models/trip.dart';
import '../../data/review_service.dart';
import '../../data/trip_service.dart';

/// A single trip with its booking/car/host detail. Auto-disposes so re-entering
/// the screen fetches fresh status.
final tripDetailProvider = FutureProvider.family<Trip, String>((ref, id) {
  return ref.watch(tripServiceProvider).get(id);
});

/// Reviews written by the current user.
final myReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) async {
  final result = await ref.watch(reviewServiceProvider).myReviews();
  return result.items;
});
