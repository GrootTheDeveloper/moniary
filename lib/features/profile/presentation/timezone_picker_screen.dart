import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../application/profile_setup_controller.dart';

class TimezonePickerScreen extends ConsumerStatefulWidget {
  const TimezonePickerScreen({super.key});

  static const routePath = '/timezone-picker';

  @override
  ConsumerState<TimezonePickerScreen> createState() =>
      _TimezonePickerScreenState();
}

class _TimezonePickerScreenState extends ConsumerState<TimezonePickerScreen> {
  List<String> _all = [];
  List<String> _filtered = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTimezones();
  }

  Future<void> _loadTimezones() async {
    try {
      final tzs = await FlutterTimezone.getAvailableTimezones();
      tzs.sort();
      if (!mounted) return;
      setState(() {
        _all = tzs;
        _filtered = tzs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((tz) => tz.toLowerCase().contains(q)).toList();
    });
  }

  String get _currentTimezone {
    return ref.read(profileSetupControllerProvider).asData?.value?.timezone ??
        AppConstants.defaultTimezone;
  }

  Future<void> _save(String tz) async {
    final profile = ref.read(profileSetupControllerProvider).asData?.value;
    if (profile == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(profileSetupControllerProvider.notifier)
          .saveProfile(
            fullName: profile.fullName ?? '',
            username: profile.username ?? '',
            timezone: tz,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, e))),
      );
    }
  }

  Future<void> _useDeviceTimezone() async {
    String tz;
    try {
      tz = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      tz = AppConstants.defaultTimezone;
    }
    if (!mounted) return;
    await _save(tz);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileSetupControllerProvider).isLoading;
    final current = _currentTimezone;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileChangeTimezone)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: context.l10n.timezonePickerSearch,
                prefixIcon: const Icon(Icons.search_outlined),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_loadError != null)
            Expanded(child: Center(child: Text(_loadError!)))
          else if (_filtered.isEmpty)
            Expanded(
              child: Center(child: Text(context.l10n.timezonePickerNoResults)),
            )
          else
            Expanded(
              child: ListView.builder(
                // +1 for the device-timezone option pinned at top
                itemCount: _filtered.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return ListTile(
                      leading: const Icon(Icons.my_location_outlined),
                      title: Text(context.l10n.timezonePickerUseDevice),
                      enabled: !saving,
                      onTap: saving ? null : _useDeviceTimezone,
                    );
                  }
                  final tz = _filtered[i - 1];
                  final isSelected = tz == current;
                  return ListTile(
                    title: Text(tz),
                    selected: isSelected,
                    selectedColor: AppTheme.mint,
                    trailing: isSelected
                        ? Icon(Icons.check_outlined, color: AppTheme.mint)
                        : null,
                    enabled: !saving,
                    onTap: saving ? null : () => _save(tz),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
