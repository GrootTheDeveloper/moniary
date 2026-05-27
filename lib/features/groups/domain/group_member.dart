class GroupMember {
  const GroupMember({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
}
