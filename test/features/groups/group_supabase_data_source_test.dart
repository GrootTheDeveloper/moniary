import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createGroup RPC is bounded by mutation timeout', () {
    final source = File(
      'lib/features/groups/data/datasources/group_supabase_data_source.dart',
    ).readAsStringSync();
    final createGroupBody = RegExp(
      r"Future<String> createGroup\([\s\S]*?\n  Future<void> updateGroup",
    ).firstMatch(source)?.group(0);

    expect(createGroupBody, isNotNull);
    expect(createGroupBody, contains("'create_expense_group'"));
    expect(createGroupBody, contains('.timeout(mutationTimeout)'));
  });
}
