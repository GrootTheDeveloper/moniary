class AccountDeletionStatus {
  AccountDeletionStatus({this.deletedAt, DateTime? scheduledDeletionAt})
    : scheduledDeletionAt =
          scheduledDeletionAt ?? deletedAt?.add(const Duration(days: 30));

  final DateTime? deletedAt;
  final DateTime? scheduledDeletionAt;

  bool get isPending => deletedAt != null;

  static final active = AccountDeletionStatus();
}
