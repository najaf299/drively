import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A promotional offer the user can apply to their next booking.
@immutable
class PromoOffer {
  final String code;
  final String title;
  final String subtitle;
  final int percentOff;
  final bool applied;

  const PromoOffer({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.percentOff,
    this.applied = false,
  });

  PromoOffer copyWith({bool? applied}) => PromoOffer(
        code: code,
        title: title,
        subtitle: subtitle,
        percentOff: percentOff,
        applied: applied ?? this.applied,
      );
}

/// Promos + loyalty state for the wallet's Promos tab.
@immutable
class PromosState {
  final int points; // loyalty points
  final List<PromoOffer> offers;
  const PromosState({required this.points, required this.offers});

  PromoOffer? get applied {
    for (final o in offers) {
      if (o.applied) return o;
    }
    return null;
  }

  PromosState copyWith({int? points, List<PromoOffer>? offers}) =>
      PromosState(points: points ?? this.points, offers: offers ?? this.offers);
}

class PromosNotifier extends StateNotifier<PromosState> {
  PromosNotifier()
      : super(const PromosState(
          points: 1240,
          offers: [
            PromoOffer(
              code: 'WELCOME15',
              title: '15% off your first trip',
              subtitle: 'New members · up to \$40 off',
              percentOff: 15,
            ),
            PromoOffer(
              code: 'WEEKEND10',
              title: '10% off weekend rentals',
              subtitle: 'Fri–Sun pickups · ends soon',
              percentOff: 10,
            ),
            PromoOffer(
              code: 'DRIVE20',
              title: '20% off premium cars',
              subtitle: 'Accent tier vehicles only',
              percentOff: 20,
            ),
          ],
        ));

  /// Applies one offer (deselecting any other). Returns the applied offer.
  PromoOffer apply(String code) {
    final target = code.trim().toUpperCase();
    state = state.copyWith(
      offers: [
        for (final o in state.offers) o.copyWith(applied: o.code == target),
      ],
    );
    return state.offers.firstWhere((o) => o.code == target);
  }

  void clear() {
    state = state.copyWith(
      offers: [for (final o in state.offers) o.copyWith(applied: false)],
    );
  }

  /// True if [code] matches a known offer.
  bool isValid(String code) =>
      state.offers.any((o) => o.code == code.trim().toUpperCase());
}

final promosProvider =
    StateNotifierProvider<PromosNotifier, PromosState>((ref) => PromosNotifier());
