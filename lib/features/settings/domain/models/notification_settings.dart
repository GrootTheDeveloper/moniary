import 'package:flutter/material.dart';

class NotificationSettings {
  final bool dailyReminderEnabled;
  final TimeOfDay? dailyReminderTime;
  final bool weeklySummaryEnabled;
  final bool monthlySummaryEnabled;
  final bool yearlySummaryEnabled;

  const NotificationSettings({
    this.dailyReminderEnabled = false,
    this.dailyReminderTime,
    this.weeklySummaryEnabled = false,
    this.monthlySummaryEnabled = false,
    this.yearlySummaryEnabled = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['daily_reminder_time'] != null) {
      final parts = json['daily_reminder_time'].toString().split(':');
      if (parts.length >= 2) {
        time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    return NotificationSettings(
      dailyReminderEnabled: json['daily_reminder_enabled'] as bool? ?? false,
      dailyReminderTime: time,
      weeklySummaryEnabled: json['weekly_summary_enabled'] as bool? ?? false,
      monthlySummaryEnabled: json['monthly_summary_enabled'] as bool? ?? false,
      yearlySummaryEnabled: json['yearly_summary_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_reminder_enabled': dailyReminderEnabled,
      'daily_reminder_time': dailyReminderTime != null
          ? '${dailyReminderTime!.hour.toString().padLeft(2, '0')}:${dailyReminderTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'weekly_summary_enabled': weeklySummaryEnabled,
      'monthly_summary_enabled': monthlySummaryEnabled,
      'yearly_summary_enabled': yearlySummaryEnabled,
    };
  }

  NotificationSettings copyWith({
    bool? dailyReminderEnabled,
    TimeOfDay? dailyReminderTime,
    bool? weeklySummaryEnabled,
    bool? monthlySummaryEnabled,
    bool? yearlySummaryEnabled,
  }) {
    return NotificationSettings(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      yearlySummaryEnabled: yearlySummaryEnabled ?? this.yearlySummaryEnabled,
    );
  }
}
