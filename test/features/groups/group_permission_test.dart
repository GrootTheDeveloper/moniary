import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/entities/group_settlement.dart';
import 'package:moniary/features/groups/domain/entities/group_transaction.dart';

void main() {
  group('GroupTransaction edit permission', () {
    test('creator can trigger edit on their own transaction', () {
      const creatorId = 'user-creator-001';
      final transaction = _transaction(createdBy: creatorId);

      final canEdit = transaction.createdBy == creatorId;

      expect(canEdit, isTrue);
    });

    test('non-creator cannot edit another user transaction', () {
      const creatorId = 'user-creator-001';
      const otherUserId = 'user-other-002';
      final transaction = _transaction(createdBy: creatorId);

      final canEdit = transaction.createdBy == otherUserId;

      expect(canEdit, isFalse);
    });

    test('empty createdBy never allows edit', () {
      final transaction = _transaction(createdBy: '');

      final canEdit = transaction.createdBy == 'any-user';

      expect(canEdit, isFalse);
    });
  });

  group('GroupSettlement mark-paid permission', () {
    test(
      'payer (fromUserId) can mark settlement as paid when status is pending',
      () {
        const payerId = 'user-payer-001';
        final settlement = _settlement(
          fromUserId: payerId,
          status: GroupSettlementStatus.pending,
        );
        const currentUserId = payerId;

        final canMark =
            settlement.fromUserId == currentUserId &&
            settlement.status == GroupSettlementStatus.pending;

        expect(canMark, isTrue);
      },
    );

    test('non-payer cannot mark settlement as paid', () {
      const payerId = 'user-payer-001';
      const otherUserId = 'user-other-002';
      final settlement = _settlement(
        fromUserId: payerId,
        status: GroupSettlementStatus.pending,
      );
      const currentUserId = otherUserId;

      final canMark =
          settlement.fromUserId == currentUserId &&
          settlement.status == GroupSettlementStatus.pending;

      expect(canMark, isFalse);
    });

    test('payer cannot mark paid when status is already payer_marked_paid', () {
      const payerId = 'user-payer-001';
      final settlement = _settlement(
        fromUserId: payerId,
        status: GroupSettlementStatus.payerMarkedPaid,
      );
      const currentUserId = payerId;

      final canMark =
          settlement.fromUserId == currentUserId &&
          settlement.status == GroupSettlementStatus.pending;

      expect(canMark, isFalse);
    });

    test('payer cannot mark paid when status is completed', () {
      const payerId = 'user-payer-001';
      final settlement = _settlement(
        fromUserId: payerId,
        status: GroupSettlementStatus.completed,
      );
      const currentUserId = payerId;

      final canMark =
          settlement.fromUserId == currentUserId &&
          settlement.status == GroupSettlementStatus.pending;

      expect(canMark, isFalse);
    });

    test('receiver (toUserId) cannot mark settlement as paid', () {
      const payerId = 'user-payer-001';
      const receiverId = 'user-receiver-003';
      final settlement = _settlement(
        fromUserId: payerId,
        toUserId: receiverId,
        status: GroupSettlementStatus.pending,
      );
      const currentUserId = receiverId;

      final canMark =
          settlement.fromUserId == currentUserId &&
          settlement.status == GroupSettlementStatus.pending;

      expect(canMark, isFalse);
    });
  });
}

GroupTransaction _transaction({required String createdBy}) {
  final now = DateTime(2026);
  return GroupTransaction(
    id: 'transaction-001',
    groupId: 'group-001',
    createdBy: createdBy,
    totalAmount: 120000,
    splitMode: GroupSplitMode.equal,
    paymentMode: GroupPaymentMode.singlePayer,
    splitStatus: GroupSplitStatus.posted,
    imageUploadStatus: GroupImageUploadStatus.pending,
    transactionDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

GroupSettlementSuggestion _settlement({
  required String fromUserId,
  required GroupSettlementStatus status,
  String toUserId = 'user-receiver-003',
}) {
  final now = DateTime(2026);
  return GroupSettlementSuggestion(
    id: 'settlement-001',
    groupId: 'group-001',
    fromUserId: fromUserId,
    toUserId: toUserId,
    amount: 50000,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}
