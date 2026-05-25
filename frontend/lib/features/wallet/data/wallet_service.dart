import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/wallet.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/json_utils.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(ref.read(dioProvider));
});

/// Customer wallet endpoints (`/customer/wallet/*`).
class WalletService {
  final Dio _dio;
  WalletService(this._dio);

  Future<Wallet> getWallet() async {
    try {
      final res = await _dio.get(ApiEndpoints.wallet);
      return Wallet.fromJson(asMap(ApiResponse.data(res.data)) ?? {});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Paginated<WalletTransaction>> transactions({
    String? type,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {if (type != null) 'type': type, 'page': page},
      );
      return Paginated<WalletTransaction>.from(
        ApiResponse.data(res.data),
        WalletTransaction.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Tops up the wallet and returns the new balance.
  Future<double> topUp(double amount) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.walletTopUp,
        data: {'amount': amount},
      );
      final data = asMap(ApiResponse.data(res.data)) ?? const {};
      return asDouble(data['new_balance']);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Withdraws [amount] to a [destination] and returns the new balance.
  /// Throws [AppException] when the balance is insufficient.
  Future<double> withdraw(double amount, {String? destination}) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.walletWithdraw,
        data: {
          'amount': amount,
          if (destination != null) 'destination': destination,
        },
      );
      final data = asMap(ApiResponse.data(res.data)) ?? const {};
      return asDouble(data['new_balance']);
    } catch (e) {
      throw mapError(e);
    }
  }
}
