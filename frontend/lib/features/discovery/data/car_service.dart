import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/car.dart';
import '../../../core/models/review.dart';
import '../../../core/network/dio_client.dart';

final carServiceProvider = Provider<CarService>((ref) {
  return CarService(ref.read(dioProvider));
});

class CarService {
  final Dio _dio;

  CarService(this._dio);

  Future<List<Car>> getCars({
    String? city,
    String? country,
    String? make,
    String? transmission,
    String? fuelType,
    int? minSeats,
    int? maxPrice,
    double? lat,
    double? lng,
    double? radius,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.cars,
        queryParameters: {
          if (city != null) 'city': city,
          if (country != null) 'country': country,
          if (make != null) 'make': make,
          if (transmission != null) 'transmission': transmission,
          if (fuelType != null) 'fuel_type': fuelType,
          if (minSeats != null) 'min_seats': minSeats,
          if (maxPrice != null) 'max_price': maxPrice,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radius != null) 'radius': radius,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          'page': page,
          'per_page': perPage,
        },
      );
      
      final cars = response.data['data'] as List;
      return cars.map((car) => Car.fromJson(car)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Car> getCarDetail(String carId) async {
    try {
      final response = await _dio.get(ApiEndpoints.carDetail(carId));
      return Car.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Review>> getCarReviews(String carId, {int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.carReviews(carId),
        queryParameters: {'page': page, 'per_page': perPage},
      );
      
      final reviews = response.data['data'] as List;
      return reviews.map((review) => Review.fromJson(review)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Car>> searchCars(String query, {int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.cars,
        queryParameters: {
          'search': query,
          'page': page,
          'per_page': perPage,
        },
      );
      
      final cars = response.data['data'] as List;
      return cars.map((car) => Car.fromJson(car)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Car>> getNearbyCars(double lat, double lng, {double radius = 10}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.cars,
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        },
      );
      
      final cars = response.data['data'] as List;
      return cars.map((car) => Car.fromJson(car)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data['message'] ?? 'An error occurred';
      
      switch (statusCode) {
        case 401:
          return Exception('Unauthorized: $message');
        case 404:
          return Exception('Car not found');
        case 422:
          return Exception('Validation error: $message');
        default:
          return Exception(message);
      }
    }
    return Exception('Network error: ${error.message}');
  }
}
