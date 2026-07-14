enum EmailAccountLinkStatus { confirmationRequired, readyToSetPassword }

class PendingEmailAccountLink {
  const PendingEmailAccountLink({required this.userId, required this.email});

  final String userId;
  final String email;

  bool matches({
    required String userId,
    required String? email,
    required bool isAnonymous,
  }) {
    return !isAnonymous &&
        this.userId == userId &&
        this.email.toLowerCase() == email?.trim().toLowerCase();
  }
}
