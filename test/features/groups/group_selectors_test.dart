import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/entities/spending_group.dart';
import 'package:moniary/features/groups/presentation/widgets/group_confirmation_dialog.dart';
import 'package:moniary/features/groups/presentation/widgets/payer_amount_input_list.dart';
import 'package:moniary/features/groups/presentation/widgets/payment_mode_selector.dart';
import 'package:moniary/features/groups/presentation/widgets/settlement_action_button.dart';
import 'package:moniary/features/groups/presentation/widgets/split_mode_selector.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app(Widget child) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('hiển thị và chọn split mode', (tester) async {
    var selected = GroupSplitMode.equal;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => SplitModeSelector(
            value: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );

    expect(find.text('Chia đều'), findsOneWidget);
    expect(find.text('Chia không đều'), findsOneWidget);

    await tester.tap(find.text('Chia không đều'));
    await tester.pump();
    expect(selected, GroupSplitMode.unequal);
  });

  testWidgets('hiển thị ba payment mode', (tester) async {
    await tester.pumpWidget(
      app(
        PaymentModeSelector(
          value: GroupPaymentMode.everyonePaid,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Mọi người đều trả'), findsOneWidget);
    expect(find.text('Một người trả'), findsOneWidget);
    expect(find.text('Nhiều người trả'), findsOneWidget);
  });

  testWidgets('multiple payers hiển thị checkbox và amount input', (
    tester,
  ) async {
    final controllers = {
      'a': TextEditingController(),
      'b': TextEditingController(),
    };
    addTearDown(() {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });
    final members = [
      SpendingGroupMember(
        id: 'member-a',
        groupId: 'group',
        userId: 'a',
        role: GroupRole.owner,
        status: GroupMemberStatus.active,
        joinedAt: DateTime(2026),
        displayName: 'A',
      ),
      SpendingGroupMember(
        id: 'member-b',
        groupId: 'group',
        userId: 'b',
        role: GroupRole.member,
        status: GroupMemberStatus.active,
        joinedAt: DateTime(2026),
        displayName: 'B',
      ),
    ];

    await tester.pumpWidget(
      app(
        PayerAmountInputList(
          members: members,
          paymentMode: GroupPaymentMode.multiplePayers,
          selectedPayerIds: const {'a', 'b'},
          controllers: controllers,
          onSingleSelected: (_) {},
          onMultipleToggled: (_, _) {},
        ),
      ),
    );

    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('bấm Hủy trong confirmation dialog trả về false', (tester) async {
    bool? result;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showGroupConfirmationDialog(
                context,
                message: 'Bạn đã chắc chắn chưa?',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã chắc chắn chưa?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cancel-group-transaction')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('nút xác nhận nhận tiền chỉ bật sau khi payer báo đã trả', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        SettlementActionButton(
          status: GroupSettlementStatus.pending,
          isReceiverAction: true,
          onPressed: () {},
        ),
      ),
    );

    var button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('confirm-settlement-received')),
    );
    expect(button.onPressed, isNull);

    await tester.pumpWidget(
      app(
        SettlementActionButton(
          status: GroupSettlementStatus.payerMarkedPaid,
          isReceiverAction: true,
          onPressed: () {},
        ),
      ),
    );
    button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('confirm-settlement-received')),
    );
    expect(button.onPressed, isNotNull);
  });
}
