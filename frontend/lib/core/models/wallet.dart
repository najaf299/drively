import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable()
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double availableBalance;
  final double pendingBalance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.availableBalance,
    required this.pendingBalance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
  Map<String, dynamic> toJson() => _$WalletToJson(this);
}

@JsonSerializable()
class WalletTransaction {
  final String id;
  final String walletId;
  final String userId;
  final String type; // 'credit', 'debit', 'refund', 'payout'
  final double amount;
  final String? description;
  final String? referenceId;
  final String? referenceType; // 'booking', 'trip', 'refund', etc.
  final String status; // 'pending', 'completed', 'failed'
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.status,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
  bool get isRefund => type == 'refund';
  bool get isPayout => type == 'payout';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

@JsonSerializable()
class TopUpRequest {
  final double amount;
  final String? paymentMethodId;
  final String currency;

  TopUpRequest({
    required this.amount,
    this.paymentMethodId,
    this.currency = 'USD',
  });

  factory TopUpRequest.fromJson(Map<String, dynamic> json) => _$TopUpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TopUpRequestToJson(this);
}
