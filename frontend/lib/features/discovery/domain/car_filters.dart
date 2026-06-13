import 'package:flutter/foundation.dart';

/// Search/filter criteria for the car discovery endpoints.
///
/// The backend `GET /cars` filter set does not include free-text search, so
/// [query] is applied client-side (matched against make/model/city). All other
/// fields map directly to query parameters.
@immutable
class CarFilters {
  final String? query; // client-side only
  final String? city;
  final String? make;
  final String? transmission; // automatic | manual
  final String? fuelType; // petrol | diesel | electric | hybrid
  final double? minPrice;
  final double? maxPrice;
  final int? minSeats;
  final int? minYear;
  final int? maxYear;
  final bool instantBooking; // only instant-bookable cars when true
  final String? sort; // price_asc | price_desc | rating
  final double? lat;
  final double? lng;
  final double? radius;

  const CarFilters({
    this.query,
    this.city,
    this.make,
    this.transmission,
    this.fuelType,
    this.minPrice,
    this.maxPrice,
    this.minSeats,
    this.minYear,
    this.maxYear,
    this.instantBooking = false,
    this.sort,
    this.lat,
    this.lng,
    this.radius,
  });

  /// Number of active server-side filters (used for the "filters applied" badge).
  int get activeCount => [
        city,
        make,
        transmission,
        fuelType,
        minPrice,
        maxPrice,
        minSeats,
        minYear,
        maxYear,
        instantBooking ? true : null,
      ].where((e) => e != null).length;

  Map<String, dynamic> toQuery() => {
        if (city != null) 'city': city,
        if (make != null) 'make': make,
        if (transmission != null) 'transmission': transmission,
        if (fuelType != null) 'fuel_type': fuelType,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (minSeats != null) 'min_seats': minSeats,
        if (minYear != null) 'min_year': minYear,
        if (maxYear != null) 'max_year': maxYear,
        if (instantBooking) 'instant_booking': true,
        if (sort != null) 'sort': sort,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (radius != null) 'radius': radius,
      };

  CarFilters copyWith({
    String? query,
    String? city,
    String? make,
    String? transmission,
    String? fuelType,
    double? minPrice,
    double? maxPrice,
    int? minSeats,
    int? minYear,
    int? maxYear,
    bool? instantBooking,
    String? sort,
    double? lat,
    double? lng,
    double? radius,
  }) {
    return CarFilters(
      query: query ?? this.query,
      city: city ?? this.city,
      make: make ?? this.make,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minSeats: minSeats ?? this.minSeats,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      instantBooking: instantBooking ?? this.instantBooking,
      sort: sort ?? this.sort,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
    );
  }

  /// Returns a copy with the named fields cleared (pass `true` to clear).
  CarFilters cleared({
    bool city = false,
    bool make = false,
    bool transmission = false,
    bool fuelType = false,
    bool price = false,
    bool seats = false,
    bool year = false,
    bool instant = false,
  }) {
    return CarFilters(
      query: query,
      city: city ? null : this.city,
      make: make ? null : this.make,
      transmission: transmission ? null : this.transmission,
      fuelType: fuelType ? null : this.fuelType,
      minPrice: price ? null : minPrice,
      maxPrice: price ? null : maxPrice,
      minSeats: seats ? null : minSeats,
      minYear: year ? null : minYear,
      maxYear: year ? null : maxYear,
      instantBooking: instant ? false : instantBooking,
      sort: sort,
      lat: lat,
      lng: lng,
      radius: radius,
    );
  }
}
