import '../utils/json_utils.dart';

/// A user's prepaid wallet balance (matches `WalletResource`).
class Wallet {
  final String id;
  final double balance;
  final String currency;
  final String? userId;

  const Wallet({
    required this.id,
    required this.balance,
    required this.currency,
    this.userId,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: asString(json['id']),
        balance: asDouble(json['balance']),
        currency: asString(json['currency'], fallback: 'USD'),
        userId: asStringOrNull(json['user_id']),
      );
}

/// A single credit/debit/refund movement (matches `WalletTransactionResource`).
class WalletTransaction {
  final String id;
  final String type; // credit | debit | refund
  final double amount;
  final double? balanceAfter;
  final String? description;
  final String? bookingId;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceAfter,
    this.description,
    this.bookingId,
    this.createdAt,
  });

  bool get isCredit => type == 'credit';
  bool get isRefund => type == 'refund';
  bool get isDebit => type == 'debit';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: asString(json['id']),
        type: asString(json['type']),
        amount: asDouble(json['amount']),
        balanceAfter: asDoubleOrNull(json['balance_after']),
        description: asStringOrNull(json['description']),
        bookingId: asStringOrNull(json['booking_id']),
        createdAt: asDateTime(json['created_at']),
      );
}
