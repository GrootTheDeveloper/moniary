import 'user_profile.dart';

class ProfileUpdateResult {
  const ProfileUpdateResult({required this.profile, this.pendingEmail});

  final UserProfile profile;
  final String? pendingEmail;

  bool get hasPendingEmailChange => pendingEmail != null;
}
