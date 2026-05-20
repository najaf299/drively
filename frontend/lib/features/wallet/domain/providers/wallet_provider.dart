import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/wallet.dart';
import '../../data/wallet_service.dart';

/// Current wallet balance.
final walletProvider = FutureProvider.autoDispose<Wallet>((ref) {
  return ref.watch(walletServiceProvider).getWallet();
});

/// Wallet transaction history (first page).
final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) async {
  final result = await ref.watch(walletServiceProvider).transactions();
  return result.items;
});
