import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/car.dart';
import '../../../core/models/review.dart';
import '../data/car_service.dart';

class CarSearchParams {
  final String? city;
  final String? country;
  final String? make;
  final String? transmission;
  final String? fuelType;
  final int? minSeats;
  final int? maxPrice;
  final double? lat;
  final double? lng;
  final double? radius;
  final String? startDate;
  final String? endDate;

  const CarSearchParams({
    this.city,
    this.country,
    this.make,
    this.transmission,
    this.fuelType,
    this.minSeats,
    this.maxPrice,
    this.lat,
    this.lng,
    this.radius,
    this.startDate,
    this.endDate,
  });

  CarSearchParams copyWith({
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
  }) {
    return CarSearchParams(
      city: city ?? this.city,
      country: country ?? this.country,
      make: make ?? this.make,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      minSeats: minSeats ?? this.minSeats,
      maxPrice: maxPrice ?? this.maxPrice,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class CarListNotifier extends StateNotifier<AsyncValue<List<Car>>> {
  final CarService _carService;

  CarListNotifier(this._carService) : super(const AsyncValue.loading());

  Future<void> loadCars(CarSearchParams params) async {
    state = const AsyncValue.loading();
    try {
      final cars = await _carService.getCars(
        city: params.city,
        country: params.country,
        make: params.make,
        transmission: params.transmission,
        fuelType: params.fuelType,
        minSeats: params.minSeats,
        maxPrice: params.maxPrice,
        lat: params.lat,
        lng: params.lng,
        radius: params.radius,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      state = AsyncValue.data(cars);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> searchCars(String query) async {
    state = const AsyncValue.loading();
    try {
      final cars = await _carService.searchCars(query);
      state = AsyncValue.data(cars);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadNearbyCars(double lat, double lng, {double radius = 10}) async {
    state = const AsyncValue.loading();
    try {
      final cars = await _carService.getNearbyCars(lat, lng, radius: radius);
      state = AsyncValue.data(cars);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final carListProvider = StateNotifierProvider<CarListNotifier, AsyncValue<List<Car>>>((ref) {
  return CarListNotifier(ref.watch(carServiceProvider));
});

final carDetailProvider = FutureProvider.family<Car, String>((ref, carId) {
  return ref.watch(carServiceProvider).getCarDetail(carId);
});

final carReviewsProvider = FutureProvider.family<List<Review>, String>((ref, carId) {
  return ref.watch(carServiceProvider).getCarReviews(carId);
});
