enum FacebookAccountLinkStatus { browserOpened }

class PendingFacebookAccountLink {
  const PendingFacebookAccountLink({required this.userId});

  final String userId;

  bool matches({required String userId, required bool hasFacebookIdentity}) {
    return this.userId == userId && hasFacebookIdentity;
  }
}
