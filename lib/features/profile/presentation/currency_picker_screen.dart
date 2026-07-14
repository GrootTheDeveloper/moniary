import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../application/profile_setup_controller.dart';
import '../domain/currency_data.dart';
import '../data/profile_repository.dart';

/// Full-screen searchable currency picker.
///
/// Usage from router:
/// ```dart
/// GoRoute(
///   path: CurrencyPickerScreen.routePath,
///   builder: (_, __) => const CurrencyPickerScreen(),
/// )
/// ```
///
/// When launched from the survey / setup flow (before the profile is persisted)
/// set [pickOnly] to true so the screen pops with the selected [CurrencyInfo]
/// instead of persisting the change itself.
class CurrencyPickerScreen extends ConsumerStatefulWidget {
  const CurrencyPickerScreen({this.pickOnly = false, super.key});

  static const routePath = '/currency-picker';

  /// When true the screen acts as a pure value picker: it pops with the
  /// selected [CurrencyInfo] and does **not** write to the repository or
  /// shared preferences.  Use this during onboarding where the caller
  /// persists the selection together with the rest of the survey/setup data.
  final bool pickOnly;

  @override
  ConsumerState<CurrencyPickerScreen> createState() =>
      _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends ConsumerState<CurrencyPickerScreen> {
  List<CurrencyInfo> _filtered = kCurrencies;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kCurrencies
          : kCurrencies.where((c) {
              return c.code.toLowerCase().contains(q) ||
                  c.name.toLowerCase().contains(q) ||
                  c.symbol.toLowerCase().contains(q) ||
                  c.country.toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _select(CurrencyInfo currency) async {
    if (widget.pickOnly) {
      context.pop(currency);
      return;
    }

    // Persist: shared prefs + profile table
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(preferredCurrencyProvider.notifier)
          .setCurrency(currency.code);

      final profile =
          ref.read(profileSetupControllerProvider).asData?.value ??
          ref.read(currentProfileProvider).value;
      if (profile != null) {
        await ref
            .read(profileRepositoryProvider)
            .completeSurvey(
              occupation: profile.occupation ?? '',
              preferredCurrency: currency.code,
            );
        ref.invalidate(currentProfileProvider);
        ref.invalidate(profileSetupControllerProvider);
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = ref.watch(preferredCurrencyProvider);
    final colors = context.moniaryColors;

    // Separate popular and the rest for display.
    final popular = _filtered.where((c) => c.popular).toList();
    final others = _filtered.where((c) => !c.popular).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.currencyPickerTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: context.l10n.currencyPickerSearch,
                prefixIcon: const Icon(Icons.search_outlined),
              ),
            ),
          ),
          if (_filtered.isEmpty)
            Expanded(
              child: Center(child: Text(context.l10n.currencyPickerNoResults)),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  if (popular.isNotEmpty) ...[
                    _SectionHeader(label: context.l10n.currencyPickerPopular),
                    ...popular.map(
                      (c) => _CurrencyTile(
                        currency: c,
                        selected: c.code == currentCode,
                        colors: colors,
                        onTap: () => _select(c),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (others.isNotEmpty) ...[
                    _SectionHeader(label: context.l10n.currencyPickerAll),
                    ...others.map(
                      (c) => _CurrencyTile(
                        currency: c,
                        selected: c.code == currentCode,
                        colors: colors,
                        onTap: () => _select(c),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.moniaryColors.textSecondary,
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.currency,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final CurrencyInfo currency;
  final bool selected;
  final MoniaryColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(currency.flag, style: const TextStyle(fontSize: 28)),
      title: Text(
        currency.name,
        style: TextStyle(
          color: selected ? colors.primary : colors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${currency.code} – ${currency.symbol}  ·  ${currency.country}',
        style: TextStyle(color: colors.textSecondary),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_outline, color: colors.primary)
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
