/// On-device daily reminder preferences (persisted locally, not in Supabase).
class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.hour = 20, this.minute = 0});

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
