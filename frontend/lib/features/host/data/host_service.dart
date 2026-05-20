import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/car.dart';
import '../../../core/models/earning.dart';
import '../../../core/models/host_verification.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/json_utils.dart';

final hostServiceProvider = Provider<HostService>((ref) {
  return HostService(ref.read(dioProvider));
});

/// Host endpoints: verification, fleet management, bookings and earnings.
class HostService {
  final Dio _dio;
  HostService(this._dio);

  // ── Verification ──────────────────────────────────────────────────────────
  Future<HostVerification> verificationStatus() async {
    try {
      final res = await _dio.get(ApiEndpoints.hostVerificationStatus);
      return HostVerification.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<HostVerification> initiateVerification() async {
    try {
      final res = await _dio.post(ApiEndpoints.hostVerificationInitiate);
      return HostVerification.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<HostVerification> updateStep(
    String step,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.hostVerificationStep,
        data: {'step': step, 'data': data},
      );
      return HostVerification.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Map<String, dynamic>> stats() async {
    try {
      final res = await _dio.get(ApiEndpoints.hostStats);
      return asMap(ApiResponse.data(res.data)) ?? const {};
    } catch (e) {
      throw mapError(e);
    }
  }

  // ── Fleet ─────────────────────────────────────────────────────────────────
  Future<Paginated<Car>> cars({String? status, int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.hostCars,
        queryParameters: {if (status != null) 'status': status, 'page': page},
      );
      return Paginated<Car>.from(ApiResponse.data(res.data), Car.fromJson);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Car> createCar(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.hostCars, data: payload);
      return Car.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Car> updateCar(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put(ApiEndpoints.hostCarDetail(id), data: payload);
      return Car.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> deleteCar(String id) async {
    try {
      await _dio.delete(ApiEndpoints.hostCarDetail(id));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> addPhotos(String carId, List<Map<String, dynamic>> photos) async {
    try {
      await _dio.post(ApiEndpoints.hostCarPhotos(carId), data: {'photos': photos});
    } catch (e) {
      throw mapError(e);
    }
  }

  // ── Bookings ────────────────────────────────────────────────────────────
  Future<Paginated<Booking>> bookings({String? status, int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.hostBookings,
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

  Future<Booking> approveBooking(String id) async {
    try {
      final res = await _dio.post(ApiEndpoints.approveBooking(id));
      return Booking.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Booking> declineBooking(String id, String reason) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.declineBooking(id),
        data: {'reason': reason},
      );
      return Booking.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  // ── Earnings ────────────────────────────────────────────────────────────
  Future<EarningsSummary> earnings({String period = 'month'}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.hostEarnings,
        queryParameters: {'period': period},
      );
      return EarningsSummary.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Paginated<Earning>> earningsHistory({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.hostEarningsHistory,
        queryParameters: {'page': page},
      );
      return Paginated<Earning>.from(
        ApiResponse.data(res.data),
        Earning.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }
}
