import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/trip.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(ref.read(dioProvider));
});

/// Trip lifecycle endpoints (start/end/extend/location).
class TripService {
  final Dio _dio;
  TripService(this._dio);

  Future<Trip> get(String tripId) async {
    try {
      final res = await _dio.get(ApiEndpoints.tripDetail(tripId));
      return Trip.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Trip> start(
    String bookingId, {
    int? mileage,
    int? fuelLevel,
    List<String>? photoUrls,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.startTrip(bookingId), data: {
        if (mileage != null) 'mileage': mileage,
        if (fuelLevel != null) 'fuel_level': fuelLevel,
        if (photoUrls != null) 'photo_urls': photoUrls,
        if (notes != null) 'notes': notes,
      });
      return Trip.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Trip> end(
    String tripId, {
    int? mileage,
    int? fuelLevel,
    List<String>? photoUrls,
    String? notes,
    bool? damageReported,
    String? damageDescription,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.endTrip(tripId), data: {
        if (mileage != null) 'mileage': mileage,
        if (fuelLevel != null) 'fuel_level': fuelLevel,
        if (photoUrls != null) 'photo_urls': photoUrls,
        if (notes != null) 'notes': notes,
        if (damageReported != null) 'damage_reported': damageReported,
        if (damageDescription != null) 'damage_description': damageDescription,
      });
      return Trip.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> updateLocation(String tripId, double lat, double lng) async {
    try {
      await _dio.post(
        ApiEndpoints.updateTripLocation(tripId),
        data: {'lat': lat, 'lng': lng},
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Trip> extend(String tripId, int extraDays) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.extendTrip(tripId),
        data: {'extra_days': extraDays},
      );
      return Trip.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }
}
