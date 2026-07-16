class NotificationDeliveryPreferences {
  const NotificationDeliveryPreferences({
    this.pushEnabled = false,
    this.personalEnabled = true,
    this.groupEnabled = true,
    this.communityEnabled = true,
    this.systemEnabled = true,
  });

  final bool pushEnabled;
  final bool personalEnabled;
  final bool groupEnabled;
  final bool communityEnabled;
  final bool systemEnabled;

  factory NotificationDeliveryPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationDeliveryPreferences(
      pushEnabled: json['push_enabled'] as bool? ?? false,
      personalEnabled: json['personal_enabled'] as bool? ?? true,
      groupEnabled: json['group_enabled'] as bool? ?? true,
      communityEnabled: json['community_enabled'] as bool? ?? true,
      systemEnabled: json['system_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'push_enabled': pushEnabled,
    'personal_enabled': personalEnabled,
    'group_enabled': groupEnabled,
    'community_enabled': communityEnabled,
    'system_enabled': systemEnabled,
  };

  NotificationDeliveryPreferences copyWith({
    bool? pushEnabled,
    bool? personalEnabled,
    bool? groupEnabled,
    bool? communityEnabled,
    bool? systemEnabled,
  }) {
    return NotificationDeliveryPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      personalEnabled: personalEnabled ?? this.personalEnabled,
      groupEnabled: groupEnabled ?? this.groupEnabled,
      communityEnabled: communityEnabled ?? this.communityEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
    );
  }
}
