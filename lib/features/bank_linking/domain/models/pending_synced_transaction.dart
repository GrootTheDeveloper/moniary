import '../../../categories/domain/models/category.dart';

enum PendingSyncedTransactionStatus { pending, confirmed, dismissed }

extension PendingSyncedTransactionStatusX on PendingSyncedTransactionStatus {
  String get value => switch (this) {
    PendingSyncedTransactionStatus.pending => 'pending',
    PendingSyncedTransactionStatus.confirmed => 'confirmed',
    PendingSyncedTransactionStatus.dismissed => 'dismissed',
  };

  static PendingSyncedTransactionStatus fromValue(String value) {
    return PendingSyncedTransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PendingSyncedTransactionStatus.pending,
    );
  }
}

class PendingSyncedTransaction {
  const PendingSyncedTransaction({
    required this.id,
    required this.bankConnectionId,
    required this.externalTransactionId,
    required this.amount,
    required this.type,
    required this.transactionDate,
    required this.status,
    required this.createdAt,
    this.merchantName,
    this.rawDescription,
  });

  final String id;
  final String bankConnectionId;
  final String externalTransactionId;
  final double amount;
  final TransactionType type;
  final DateTime transactionDate;
  final String? merchantName;
  final String? rawDescription;
  final PendingSyncedTransactionStatus status;
  final DateTime createdAt;

  factory PendingSyncedTransaction.fromMap(Map<String, dynamic> map) {
    return PendingSyncedTransaction(
      id: map['id'] as String,
      bankConnectionId: map['bank_connection_id'] as String,
      externalTransactionId: map['external_transaction_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: (map['type'] as String) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      merchantName: map['merchant_name'] as String?,
      rawDescription: map['raw_description'] as String?,
      status: PendingSyncedTransactionStatusX.fromValue(
        map['status'] as String,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PendingSyncedTransaction copyWith({PendingSyncedTransactionStatus? status}) {
    return PendingSyncedTransaction(
      id: id,
      bankConnectionId: bankConnectionId,
      externalTransactionId: externalTransactionId,
      amount: amount,
      type: type,
      transactionDate: transactionDate,
      merchantName: merchantName,
      rawDescription: rawDescription,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
