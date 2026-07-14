import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupNotificationPreferencesScreen extends ConsumerWidget {
  const GroupNotificationPreferencesScreen({required this.groupId, super.key});

  static const routePath = '/groups/notification-preferences';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefAsync = ref.watch(groupNotificationPreferenceProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupNotificationPrefsTitle)),
      body: prefAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              userFriendlyMessage(context, error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (preference) =>
            _PreferencesForm(groupId: groupId, initial: preference),
      ),
    );
  }
}

class _PreferencesForm extends ConsumerStatefulWidget {
  const _PreferencesForm({required this.groupId, required this.initial});

  final String groupId;
  final GroupNotificationPreference initial;

  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  late bool _muteAll;
  late bool _transaction;
  late bool _debt;
  late bool _invite;
  late bool _mention;
  late bool _quietHoursEnabled;
  late int _quietStart;
  late int _quietEnd;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _muteAll = p.muteAll;
    _transaction = p.transactionNotifications;
    _debt = p.debtNotifications;
    _invite = p.inviteNotifications;
    _mention = p.mentionNotifications;
    _quietHoursEnabled = p.quietHoursStart != null && p.quietHoursEnd != null;
    _quietStart = p.quietHoursStart ?? 22;
    _quietEnd = p.quietHoursEnd ?? 7;
  }

  @override
  Widget build(BuildContext context) {
    final typesEnabled = !_muteAll;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            children: [
              SwitchListTile(
                value: _muteAll,
                onChanged: (value) => setState(() => _muteAll = value),
                title: Text(context.l10n.groupNotificationPrefsMuteAll),
                subtitle: Text(context.l10n.groupNotificationPrefsMuteAllHelp),
                secondary: const Icon(Icons.notifications_off_outlined),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: typesEnabled && _transaction,
                onChanged: typesEnabled
                    ? (value) => setState(() => _transaction = value)
                    : null,
                title: Text(context.l10n.groupNotificationPrefsTransactions),
                secondary: const Icon(Icons.receipt_long_outlined),
              ),
              SwitchListTile(
                value: typesEnabled && _debt,
                onChanged: typesEnabled
                    ? (value) => setState(() => _debt = value)
                    : null,
                title: Text(context.l10n.groupNotificationPrefsDebts),
                secondary: const Icon(Icons.account_balance_wallet_outlined),
              ),
              SwitchListTile(
                value: typesEnabled && _invite,
                onChanged: typesEnabled
                    ? (value) => setState(() => _invite = value)
                    : null,
                title: Text(context.l10n.groupNotificationPrefsInvites),
                secondary: const Icon(Icons.person_add_outlined),
              ),
              SwitchListTile(
                value: typesEnabled && _mention,
                onChanged: typesEnabled
                    ? (value) => setState(() => _mention = value)
                    : null,
                title: Text(context.l10n.groupNotificationPrefsMentions),
                secondary: const Icon(Icons.alternate_email_outlined),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _quietHoursEnabled,
                onChanged: (value) =>
                    setState(() => _quietHoursEnabled = value),
                title: Text(context.l10n.groupNotificationPrefsQuietHours),
                subtitle: Text(
                  context.l10n.groupNotificationPrefsQuietHoursHelp,
                ),
                secondary: const Icon(Icons.bedtime_outlined),
              ),
              if (_quietHoursEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HourPicker(
                          label: context.l10n.groupNotificationPrefsFrom,
                          value: _quietStart,
                          onChanged: (value) =>
                              setState(() => _quietStart = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _HourPicker(
                          label: context.l10n.groupNotificationPrefsTo,
                          value: _quietEnd,
                          onChanged: (value) =>
                              setState(() => _quietEnd = value),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting
                      ? context.l10n.commonSaving
                      : context.l10n.commonSave,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);

    final preference = GroupNotificationPreference(
      groupId: widget.groupId,
      muteAll: _muteAll,
      transactionNotifications: _transaction,
      debtNotifications: _debt,
      inviteNotifications: _invite,
      mentionNotifications: _mention,
      quietHoursStart: _quietHoursEnabled ? _quietStart : null,
      quietHoursEnd: _quietHoursEnabled ? _quietEnd : null,
    );

    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .updateNotificationPreference(preference);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupNotificationPrefsSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: List.generate(
        24,
        (hour) => DropdownMenuItem(
          value: hour,
          child: Text('${hour.toString().padLeft(2, '0')}:00'),
        ),
      ),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
