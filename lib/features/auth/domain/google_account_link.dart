enum GoogleAccountLinkStatus { browserOpened, completed }

class PendingGoogleAccountLink {
  const PendingGoogleAccountLink({required this.userId});

  final String userId;

  bool matches({required String userId, required bool hasGoogleIdentity}) {
    return this.userId == userId && hasGoogleIdentity;
  }
}

enum AccountLinkNotice { googleSuccess, googleFailure }
