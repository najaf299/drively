import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/car.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.read(dioProvider));
});

/// Saved/favourite cars (`/customer/favorites`). The list endpoint returns the
/// favourited cars directly.
class FavoriteService {
  final Dio _dio;
  FavoriteService(this._dio);

  Future<List<Car>> list() async {
    try {
      final res = await _dio.get(ApiEndpoints.favorites);
      return Paginated<Car>.from(ApiResponse.data(res.data), Car.fromJson)
          .items;
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Toggles favourite state. Returns `true` if the car is now favourited
  /// (HTTP 201), `false` if it was removed (HTTP 200).
  Future<bool> toggle(String carId) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.toggleFavorite,
        data: {'car_id': carId},
      );
      return res.statusCode == 201;
    } catch (e) {
      throw mapError(e);
    }
  }
}
