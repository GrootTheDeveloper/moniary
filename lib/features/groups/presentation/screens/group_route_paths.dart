abstract final class GroupRoutePaths {
  const GroupRoutePaths._();

  static const groupPattern = '/groups/:groupId';
  static const homePattern = '/groups/:groupId/home';
  static const communityPattern = '/groups/:groupId/community';
  static const notificationsPattern = '/groups/:groupId/notifications';
  static const managementPattern = '/groups/:groupId/management';

  static const settlementsPattern = '$homePattern/settlements';
  static const summaryPattern = '$homePattern/summary';
  static const transactionsPattern = '$homePattern/transactions';
  static const transactionFormPattern = '$homePattern/transactions/new';
  static const transactionDetailPattern =
      '$homePattern/transactions/:transactionId';
  static const memberAmountPattern =
      '$homePattern/transactions/:transactionId/member-amount';

  static const albumPattern = '$communityPattern/album';
  static const participationPattern = '$communityPattern/participation';

  static const budgetPattern = '$managementPattern/budget';
  static const recurringPattern = '$managementPattern/recurring';
  static const notificationPreferencesPattern =
      '$managementPattern/notification-preferences';
  static const publicProfilePattern = '$managementPattern/public-profile';
  static const auditLogPattern = '$managementPattern/audit-log';
  static const settingsPattern = '$managementPattern/settings';
  static const invitePattern = '$managementPattern/invite';

  static String _segment(String value) => Uri.encodeComponent(value);

  static String home(String groupId) => '/groups/${_segment(groupId)}/home';

  static String community(String groupId) =>
      '/groups/${_segment(groupId)}/community';

  static String notifications(String groupId) =>
      '/groups/${_segment(groupId)}/notifications';

  static String management(String groupId) =>
      '/groups/${_segment(groupId)}/management';

  static String settlements(String groupId) => '${home(groupId)}/settlements';

  static String summary(String groupId) => '${home(groupId)}/summary';

  static String transactions(String groupId) => '${home(groupId)}/transactions';

  static String transactionForm(String groupId) =>
      '${home(groupId)}/transactions/new';

  static String transactionDetail({
    required String groupId,
    required String transactionId,
  }) => '${home(groupId)}/transactions/${_segment(transactionId)}';

  static String memberAmount({
    required String groupId,
    required String transactionId,
  }) =>
      '${transactionDetail(groupId: groupId, transactionId: transactionId)}/member-amount';

  static String album(String groupId) => '${community(groupId)}/album';

  static String participation(String groupId) =>
      '${community(groupId)}/participation';

  static String budget(String groupId) => '${management(groupId)}/budget';

  static String recurring(String groupId) => '${management(groupId)}/recurring';

  static String notificationPreferences(String groupId) =>
      '${management(groupId)}/notification-preferences';

  static String publicProfile(String groupId) =>
      '${management(groupId)}/public-profile';

  static String auditLog(String groupId) => '${management(groupId)}/audit-log';

  static String settings(String groupId) => '${management(groupId)}/settings';

  static String invite(String groupId) => '${management(groupId)}/invite';
}
