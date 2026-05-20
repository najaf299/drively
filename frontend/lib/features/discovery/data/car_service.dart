import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/car.dart';
import '../../../core/models/review.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/json_utils.dart';
import '../domain/car_filters.dart';

final carServiceProvider = Provider<CarService>((ref) {
  return CarService(ref.read(dioProvider));
});

/// Full car detail bundle returned by `GET /cars/{id}`:
/// `{ car, suggested_price, total_reviews }`.
class CarDetailResult {
  final Car car;
  final double? suggestedPrice;
  final int totalReviews;

  const CarDetailResult({
    required this.car,
    this.suggestedPrice,
    this.totalReviews = 0,
  });
}

/// Read access to the public car catalogue.
class CarService {
  final Dio _dio;
  CarService(this._dio);

  /// Searches cars with [filters]. The free-text [CarFilters.query] (if any) is
  /// applied client-side since the API has no text-search parameter.
  Future<Paginated<Car>> search(
    CarFilters filters, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.cars,
        queryParameters: {
          ...filters.toQuery(),
          'page': page,
          'per_page': perPage,
        },
      );
      final result = Paginated<Car>.from(
        ApiResponse.data(res.data),
        Car.fromJson,
      );
      final q = filters.query?.trim().toLowerCase();
      if (q == null || q.isEmpty) return result;

      final filtered = result.items.where((c) {
        return c.displayNameWithYear.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q);
      }).toList();
      return Paginated<Car>(items: filtered, total: filtered.length);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<CarDetailResult> getCar(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.carDetail(id));
      final data = asMap(ApiResponse.data(res.data)) ?? const {};
      return CarDetailResult(
        car: Car.fromJson(Map<String, dynamic>.from(data['car'])),
        suggestedPrice: asDoubleOrNull(data['suggested_price']),
        totalReviews: asInt(data['total_reviews']),
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Paginated<Review>> getReviews(String carId, {int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.carReviews(carId),
        queryParameters: {'page': page},
      );
      return Paginated<Review>.from(
          ApiResponse.data(res.data), Review.fromJson);
    } catch (e) {
      throw mapError(e);
    }
  }
}
