import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A saved payment card. Stored client-side for the prototype — in production
/// these are tokenised by Stripe and only the brand/last-four are kept.
@immutable
class SavedCard {
  final String id;
  final String brand; // Visa | Mastercard | Amex
  final String lastFour;
  final String expiry; // MM/YY
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.brand,
    required this.lastFour,
    required this.expiry,
    this.isDefault = false,
  });

  SavedCard copyWith({bool? isDefault}) => SavedCard(
        id: id,
        brand: brand,
        lastFour: lastFour,
        expiry: expiry,
        isDefault: isDefault ?? this.isDefault,
      );
}

/// Manages the user's saved cards (add / remove / set default). Seeded with two
/// demo cards so the wallet looks populated on first run.
class SavedCardsNotifier extends StateNotifier<List<SavedCard>> {
  SavedCardsNotifier()
      : super(const [
          SavedCard(
              id: 'c1',
              brand: 'Visa',
              lastFour: '4829',
              expiry: '08/27',
              isDefault: true),
          SavedCard(
              id: 'c2',
              brand: 'Mastercard',
              lastFour: '1245',
              expiry: '09/27'),
        ]);

  void add({
    required String brand,
    required String lastFour,
    required String expiry,
  }) {
    final card = SavedCard(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      brand: brand,
      lastFour: lastFour,
      expiry: expiry,
      isDefault: state.isEmpty,
    );
    state = [...state, card];
  }

  void remove(String id) {
    final removed = state.firstWhere((c) => c.id == id);
    var next = state.where((c) => c.id != id).toList();
    // If we removed the default, promote the first remaining card.
    if (removed.isDefault && next.isNotEmpty) {
      next = [
        next.first.copyWith(isDefault: true),
        ...next.skip(1),
      ];
    }
    state = next;
  }

  void setDefault(String id) {
    state = [
      for (final c in state) c.copyWith(isDefault: c.id == id),
    ];
  }
}

final savedCardsProvider =
    StateNotifierProvider<SavedCardsNotifier, List<SavedCard>>(
  (ref) => SavedCardsNotifier(),
);
