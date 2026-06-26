import 'group_enums.dart';

class GroupBalance {
  const GroupBalance({
    required this.groupId,
    required this.userId,
    required this.totalShareAmount,
    required this.totalPaidAmount,
    required this.balance,
    this.displayName,
  });

  final String groupId;
  final String userId;
  final int totalShareAmount;
  final int totalPaidAmount;
  final int balance;
  final String? displayName;
}

class GroupSettlementSuggestion {
  const GroupSettlementSuggestion({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.payerMarkedPaidAt,
    this.receiverConfirmedAt,
    this.fromDisplayName,
    this.toDisplayName,
  });

  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final int amount;
  final GroupSettlementStatus status;
  final DateTime? payerMarkedPaidAt;
  final DateTime? receiverConfirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fromDisplayName;
  final String? toDisplayName;
}

class GroupSettlementOverview {
  const GroupSettlementOverview({
    required this.balances,
    required this.suggestions,
  });

  final List<GroupBalance> balances;
  final List<GroupSettlementSuggestion> suggestions;
}
