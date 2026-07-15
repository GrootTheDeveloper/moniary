import 'group_enums.dart';

class GroupTransaction {
  const GroupTransaction({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.totalAmount,
    required this.splitMode,
    required this.paymentMode,
    required this.splitStatus,
    required this.imageUploadStatus,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.currencyCode = 'VND',
    this.exchangeRateToBase = 1,
    int? baseTotalAmount,
    this.categoryId,
    this.categoryName,
    this.caption,
    this.note,
    this.imagePath,
    this.creatorName,
    this.hasCompletedSettlement = false,
    this.hasSettlementLock = false,
  }) : baseTotalAmount = baseTotalAmount ?? totalAmount;

  final String id;
  final String groupId;
  final String createdBy;
  final int totalAmount;
  final String currencyCode;
  final double exchangeRateToBase;
  final int baseTotalAmount;
  final String? categoryId;
  final String? categoryName;
  final String? caption;
  final String? note;
  final String? imagePath;
  final GroupImageUploadStatus imageUploadStatus;
  final GroupSplitMode splitMode;
  final GroupPaymentMode paymentMode;
  final GroupSplitStatus splitStatus;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? creatorName;
  final bool hasCompletedSettlement;
  final bool hasSettlementLock;

  // The base amount is the only amount used for balances and budgets.
  // Legacy rows default to totalAmount.
  int get resolvedBaseTotalAmount => baseTotalAmount;
}

class GroupTransactionPage {
  const GroupTransactionPage({required this.items, required this.hasMore});

  final List<GroupTransaction> items;
  final bool hasMore;
}

class GroupTransactionPayer {
  const GroupTransactionPayer({
    required this.id,
    required this.groupTransactionId,
    required this.userId,
    required this.paidAmount,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
  });

  final String id;
  final String groupTransactionId;
  final String userId;
  final int paidAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? displayName;
}

class GroupTransactionShare {
  const GroupTransactionShare({
    required this.id,
    required this.groupTransactionId,
    required this.userId,
    required this.shareAmount,
    required this.inputStatus,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.displayName,
  });

  final String id;
  final String groupTransactionId;
  final String userId;
  final int shareAmount;
  final GroupShareInputStatus inputStatus;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? displayName;
}

class GroupTransactionComment {
  const GroupTransactionComment({
    required this.id,
    required this.groupTransactionId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.avatarPath,
  });

  final String id;
  final String groupTransactionId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? displayName;
  final String? avatarPath;
}

class GroupTransactionDetail {
  const GroupTransactionDetail({
    required this.transaction,
    required this.payers,
    required this.shares,
    required this.comments,
  });

  final GroupTransaction transaction;
  final List<GroupTransactionPayer> payers;
  final List<GroupTransactionShare> shares;
  final List<GroupTransactionComment> comments;
}

class GroupTransactionDraft {
  const GroupTransactionDraft({
    required this.groupId,
    required this.totalAmount,
    required this.splitMode,
    required this.paymentMode,
    required this.payerAmounts,
    this.participantIds = const [],
    this.shareAmounts = const {},
    this.categoryId,
    this.categoryName,
    this.caption,
    this.note,
    this.imageFilePath,
    this.currencyCode = 'VND',
    this.exchangeRateToBase = 1,
  });

  final String groupId;
  final int totalAmount;
  final String? categoryId;
  final String? categoryName;
  final String? caption;
  final String? note;
  final String? imageFilePath;
  final String currencyCode;
  final double exchangeRateToBase;
  final GroupSplitMode splitMode;
  final GroupPaymentMode paymentMode;
  final Map<String, int> payerAmounts;
  final List<String> participantIds;
  final Map<String, int> shareAmounts;
}
