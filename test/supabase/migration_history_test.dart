import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase migration versions are unique and well formed', () {
    final files = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList();
    final pattern = RegExp(r'^(\d{14})_[a-z0-9_]+\.sql$');
    final versions = <String, List<String>>{};
    final malformed = <String>[];

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final match = pattern.firstMatch(name);
      if (match == null) {
        malformed.add(name);
        continue;
      }
      versions.putIfAbsent(match.group(1)!, () => []).add(name);
    }

    final duplicates = versions.values
        .where((names) => names.length > 1)
        .expand((names) => names)
        .toList();
    expect(
      malformed,
      isEmpty,
      reason: 'Every migration needs a 14-digit version.',
    );
    expect(duplicates, isEmpty, reason: 'Migration versions must be unique.');
  });

  test('branch-collision reconciliation retains all schema changes', () {
    final groupLeave = File(
      'supabase/migrations/'
      '20260715000100_group_leave_guards_and_notification_channels.sql',
    ).readAsStringSync();
    final notifications = File(
      'supabase/migrations/'
      '20260715000200_notifications_inbox_and_devices.sql',
    ).readAsStringSync();
    final lifecycle = File(
      'supabase/migrations/'
      '20260715000300_group_lifecycle_and_recurring_source.sql',
    ).readAsStringSync();

    expect(groupLeave, contains('leave_expense_group'));
    expect(notifications, contains('notification_devices'));
    expect(lifecycle, contains("add value if not exists 'recurring'"));
    expect(lifecycle, contains('notify_group_settlement_change'));
  });
}
