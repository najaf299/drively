import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/car.dart';
import '../../../../core/models/review.dart';
import '../../../../core/network/api_response.dart';
import '../../data/car_service.dart';
import '../../data/favorite_service.dart';
import '../car_filters.dart';

/// The active discovery filters (search bar + filter sheet write here).
final carFiltersProvider =
    StateProvider<CarFilters>((ref) => const CarFilters());

/// Paginated, filter-driven car list backing the Home and Search screens.
class CarListNotifier extends StateNotifier<AsyncValue<List<Car>>> {
  final CarService _service;
  CarListNotifier(this._service) : super(const AsyncValue.loading());

  CarFilters _filters = const CarFilters();
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  /// Loads page 1 for [filters] (replaces the current list).
  Future<void> load(CarFilters filters) async {
    _filters = filters;
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    try {
      final result = await _service.search(filters, page: _page);
      _hasMore = result.hasMore;
      state = AsyncValue.data(result.items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load(_filters);

  /// Appends the next page for infinite scroll.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.valueOrNull ?? const <Car>[];
    _loadingMore = true;
    try {
      final result = await _service.search(_filters, page: _page + 1);
      _page += 1;
      _hasMore = result.hasMore;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {
      // Keep the existing page on a load-more failure.
    } finally {
      _loadingMore = false;
    }
  }
}

final carListProvider =
    StateNotifierProvider<CarListNotifier, AsyncValue<List<Car>>>((ref) {
  return CarListNotifier(ref.watch(carServiceProvider));
});

/// Full detail bundle for a single car.
final carDetailProvider =
    FutureProvider.family<CarDetailResult, String>((ref, id) {
  return ref.watch(carServiceProvider).getCar(id);
});

/// Paginated reviews for a car (first page).
final carReviewsProvider =
    FutureProvider.family<Paginated<Review>, String>((ref, id) {
  return ref.watch(carServiceProvider).getReviews(id);
});

/// The current user's favourite cars.
final favoritesProvider = FutureProvider.autoDispose<List<Car>>((ref) {
  return ref.watch(favoriteServiceProvider).list();
});
