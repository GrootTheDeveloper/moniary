class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.loginProvider,
    required this.timezone,
    this.username,
    this.occupation,
    this.preferredCurrency = 'VND',
    this.surveyCompleted = true,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String loginProvider;
  final String timezone;
  final String? username;
  final String? occupation;
  final String preferredCurrency;
  final bool surveyCompleted;

  bool get needsSetup {
    final name = fullName?.trim() ?? '';
    // Assumption: default displayName from Supabase trigger is 'guest'
    return name.isEmpty || name.toLowerCase() == 'guest';
  }

  bool get needsSurvey => !surveyCompleted;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      loginProvider: (map['login_provider'] as String?) ?? 'anonymous',
      timezone: (map['timezone'] as String?) ?? 'Asia/Ho_Chi_Minh',
      username: map['username'] as String?,
      occupation: map['occupation'] as String?,
      preferredCurrency: (map['preferred_currency'] as String?) ?? 'VND',
      surveyCompleted: map['survey_completed_at'] != null,
    );
  }
}
