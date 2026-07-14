enum GroupRole { owner, admin, member }

enum GroupMemberStatus { invited, active, declined, left, removed }

enum GroupStatus { active, archived }

enum GroupSplitMode { equal, exact, unequal }

enum GroupPaymentMode { everyonePaid, singlePayer, multiplePayers }

enum GroupSplitStatus {
  draft,
  pendingMemberAmountInput,
  amountMismatch,
  posted,
  cancelled,
}

enum GroupShareInputStatus { pending, submitted }

enum GroupSettlementStatus { pending, payerMarkedPaid, completed, disputed }

enum GroupImageUploadStatus { pending, uploading, uploaded, failed }

extension GroupRoleValue on GroupRole {
  String get value => name;

  static GroupRole fromValue(String value) => GroupRole.values.firstWhere(
    (item) => item.value == value,
    orElse: () => GroupRole.member,
  );
}

extension GroupMemberStatusValue on GroupMemberStatus {
  String get value => name;

  static GroupMemberStatus fromValue(String value) =>
      GroupMemberStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => GroupMemberStatus.invited,
      );
}

extension GroupStatusValue on GroupStatus {
  String get value => name;

  static GroupStatus fromValue(String value) => GroupStatus.values.firstWhere(
    (item) => item.value == value,
    orElse: () => GroupStatus.active,
  );
}

extension GroupSplitModeValue on GroupSplitMode {
  String get value => name;

  static GroupSplitMode fromValue(String value) =>
      GroupSplitMode.values.firstWhere(
        (item) => item.value == value,
        orElse: () => GroupSplitMode.equal,
      );
}

extension GroupPaymentModeValue on GroupPaymentMode {
  String get value => switch (this) {
    GroupPaymentMode.everyonePaid => 'everyone_paid',
    GroupPaymentMode.singlePayer => 'single_payer',
    GroupPaymentMode.multiplePayers => 'multiple_payers',
  };

  static GroupPaymentMode fromValue(String value) => switch (value) {
    'single_payer' => GroupPaymentMode.singlePayer,
    'multiple_payers' => GroupPaymentMode.multiplePayers,
    _ => GroupPaymentMode.everyonePaid,
  };
}

extension GroupSplitStatusValue on GroupSplitStatus {
  String get value => switch (this) {
    GroupSplitStatus.pendingMemberAmountInput => 'pending_member_amount_input',
    GroupSplitStatus.amountMismatch => 'amount_mismatch',
    _ => name,
  };

  static GroupSplitStatus fromValue(String value) => switch (value) {
    'pending_member_amount_input' => GroupSplitStatus.pendingMemberAmountInput,
    'amount_mismatch' => GroupSplitStatus.amountMismatch,
    'posted' => GroupSplitStatus.posted,
    'cancelled' => GroupSplitStatus.cancelled,
    _ => GroupSplitStatus.draft,
  };
}

extension GroupShareInputStatusValue on GroupShareInputStatus {
  String get value => name;

  static GroupShareInputStatus fromValue(String value) =>
      GroupShareInputStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => GroupShareInputStatus.pending,
      );
}

extension GroupSettlementStatusValue on GroupSettlementStatus {
  String get value => switch (this) {
    GroupSettlementStatus.payerMarkedPaid => 'payer_marked_paid',
    _ => name,
  };

  static GroupSettlementStatus fromValue(String value) => switch (value) {
    'payer_marked_paid' => GroupSettlementStatus.payerMarkedPaid,
    'completed' => GroupSettlementStatus.completed,
    'disputed' => GroupSettlementStatus.disputed,
    _ => GroupSettlementStatus.pending,
  };
}

extension GroupImageUploadStatusValue on GroupImageUploadStatus {
  String get value => name;

  static GroupImageUploadStatus fromValue(String value) =>
      GroupImageUploadStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => GroupImageUploadStatus.pending,
      );
}
