import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/booking.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/json_utils.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

/// Customer booking endpoints (`/customer/bookings/*`).
class BookingService {
  final Dio _dio;
  BookingService(this._dio);

  Future<Paginated<Booking>> list({String? status, int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.customerBookings,
        queryParameters: {if (status != null) 'status': status, 'page': page},
      );
      return Paginated<Booking>.from(
        ApiResponse.data(res.data),
        Booking.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Booking> get(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.bookingDetail(id));
      return Booking.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Price preview before committing to a booking.
  Future<BookingPricing> pricing({
    required String carId,
    required DateTime pickupAt,
    required DateTime returnAt,
    String? promoCode,
    List<dynamic>? addons,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.bookingPricing, data: {
        'car_id': carId,
        'pickup_at': pickupAt.toUtc().toIso8601String(),
        'return_at': returnAt.toUtc().toIso8601String(),
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
        if (addons != null) 'addons': addons,
      });
      return BookingPricing.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Booking> create({
    required String carId,
    required DateTime pickupAt,
    required DateTime returnAt,
    required String pickupAddress,
    List<dynamic>? addons,
    String? promoCode,
    String bookingType = 'instant',
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.customerBookings, data: {
        'car_id': carId,
        'pickup_at': pickupAt.toUtc().toIso8601String(),
        'return_at': returnAt.toUtc().toIso8601String(),
        'pickup_address': pickupAddress,
        'booking_type': bookingType,
        if (addons != null) 'addons': addons,
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      });
      return Booking.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Booking> cancel(String id, String reason) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.cancelBooking(id),
        data: {'reason': reason},
      );
      return Booking.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Creates a payment intent for the booking; returns the raw gateway payload
  /// (e.g. `client_secret`) for the Stripe Payment Sheet.
  Future<Map<String, dynamic>> pay(String id) async {
    try {
      final res = await _dio.post(ApiEndpoints.payBooking(id));
      return asMap(ApiResponse.data(res.data)) ?? const {};
    } catch (e) {
      throw mapError(e);
    }
  }
}
