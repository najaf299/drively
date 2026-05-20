import '../../../core/models/car.dart';

/// In-flight booking selection passed between the Date/Time picker and the
/// Booking Summary screens via GoRouter `extra`.
class BookingDraft {
  final Car car;
  final DateTime pickupAt;
  final DateTime returnAt;

  const BookingDraft({
    required this.car,
    required this.pickupAt,
    required this.returnAt,
  });

  int get totalDays {
    final days = returnAt.difference(pickupAt).inDays;
    return days < 1 ? 1 : days;
  }

  BookingDraft copyWith({DateTime? pickupAt, DateTime? returnAt}) =>
      BookingDraft(
        car: car,
        pickupAt: pickupAt ?? this.pickupAt,
        returnAt: returnAt ?? this.returnAt,
      );
}
