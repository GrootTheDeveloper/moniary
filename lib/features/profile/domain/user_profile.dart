class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.loginProvider,
    required this.timezone,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String loginProvider;
  final String timezone;

  bool get needsSetup {
    final name = fullName?.trim() ?? '';
    // Assumption: default displayName from Supabase trigger is 'guest'
    return name.isEmpty || name.toLowerCase() == 'guest';
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      loginProvider: (map['login_provider'] as String?) ?? 'anonymous',
      timezone: (map['timezone'] as String?) ?? 'Asia/Ho_Chi_Minh',
    );
  }
}
