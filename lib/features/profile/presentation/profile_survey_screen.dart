import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/deeplinks/pending_deep_link_controller.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/brand/brand_assets.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../application/profile_setup_controller.dart';
import '../application/profile_survey_controller.dart';
import '../domain/currency_data.dart';
import 'currency_picker_screen.dart';

class ProfileSurveyScreen extends ConsumerStatefulWidget {
  const ProfileSurveyScreen({super.key});

  static const routePath = '/profile-survey';

  @override
  ConsumerState<ProfileSurveyScreen> createState() =>
      _ProfileSurveyScreenState();
}

class _ProfileSurveyScreenState extends ConsumerState<ProfileSurveyScreen> {
  final _walletNameController = TextEditingController();
  final _amountController = TextEditingController();

  int _step = 0;
  String? _occupation;
  String _currency = 'VND';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_walletNameController.text.isEmpty) {
      _walletNameController.text = context.l10n.profileSurveyWalletDefaultName;
    }
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final profile = ref.watch(currentProfileProvider).value;
    final surveyAction = ref.watch(profileSurveyControllerProvider);
    final name = profile?.fullName?.trim();
    final displayName = name?.isNotEmpty == true
        ? name!
        : context.l10n.profileSurveyFallbackName;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step > 0) {
          setState(() => _step -= 1);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: _step == 0
                          ? null
                          : IconButton(
                              onPressed: surveyAction.isLoading
                                  ? null
                                  : () => setState(() => _step -= 1),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_outlined,
                                size: 19,
                              ),
                            ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / 4,
                          minHeight: 5,
                          color: colors.primary,
                          backgroundColor: colors.textPrimary.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [...previousChildren, ?currentChild],
                    );
                  },
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: switch (_step) {
                    0 => _WelcomeStep(
                      key: const ValueKey(0),
                      name: displayName,
                    ),
                    1 => _OccupationStep(
                      key: const ValueKey(1),
                      selected: _occupation,
                      onSelected: (value) =>
                          setState(() => _occupation = value),
                    ),
                    2 => _CurrencyStep(
                      key: const ValueKey(2),
                      selected: _currency,
                      onSelected: (value) => setState(() => _currency = value),
                    ),
                    _ => _WalletStep(
                      key: const ValueKey(3),
                      walletNameController: _walletNameController,
                      amountController: _amountController,
                      currency: _currency,
                    ),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: FilledButton(
                  onPressed: surveyAction.isLoading ? null : _next,
                  child: surveyAction.isLoading
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.background,
                          ),
                        )
                      : Text(
                          _step == 3
                              ? context.l10n.profileSurveyFinish
                              : context.l10n.profileSurveyNext,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (_step == 1 && _occupation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSurveyOccupationTitle)),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }

    final walletName = _walletNameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (walletName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSurveyWalletName)),
      );
      return;
    }

    await ref
        .read(profileSurveyControllerProvider.notifier)
        .complete(
          occupation: _occupation!,
          preferredCurrency: _currency,
          walletName: walletName,
          initialBalance: amount,
        );
    if (!mounted) return;
    final result = ref.read(profileSurveyControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, result.error!))),
      );
      return;
    }

    final pendingRoute = ref.read(pendingDeepLinkProvider.notifier).consume();
    final friendInviteToken = friendInviteTokenFromRouteLocation(pendingRoute);
    if (friendInviteToken != null) {
      ref
          .read(pendingFriendInvitePromptProvider.notifier)
          .set(friendInviteToken);
      context.go(CalendarScreen.routePath);
      return;
    }
    context.go(pendingRoute ?? CalendarScreen.routePath);
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.outline),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Image.asset(
              BrandAssets.appLogo,
              semanticLabel: context.l10n.loginTitle,
            ),
          ),
          const SizedBox(height: 34),
          Text(
            context.l10n.profileSurveyWelcomeTitle(name),
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.profileSurveyWelcomeBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _OccupationStep extends StatelessWidget {
  const _OccupationStep({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String, IconData)>[
      (
        'student',
        context.l10n.profileSurveyOccupationStudent,
        Icons.school_outlined,
      ),
      (
        'office_worker',
        context.l10n.profileSurveyOccupationOffice,
        Icons.badge_outlined,
      ),
      (
        'freelancer',
        context.l10n.profileSurveyOccupationFreelancer,
        Icons.laptop_mac_outlined,
      ),
      (
        'business_owner',
        context.l10n.profileSurveyOccupationBusiness,
        Icons.storefront_outlined,
      ),
      (
        'other',
        context.l10n.profileSurveyOccupationOther,
        Icons.more_horiz_outlined,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.profileSurveyOccupationTitle,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.profileSurveyOccupationBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectionTile(
                label: option.$2,
                icon: option.$3,
                selected: selected == option.$1,
                onTap: () => onSelected(option.$1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyStep extends StatelessWidget {
  const _CurrencyStep({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final info = currencyInfoFor(selected);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.profileSurveyCurrencyTitle,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.profileSurveyCurrencyBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 36),
          MoniaryHairlineTile(
            title: Text(info.name),
            subtitle: Text('${info.code} – ${info.symbol}  ·  ${info.country}'),
            leading: Text(info.flag, style: const TextStyle(fontSize: 28)),
            trailing: Icon(
              Icons.chevron_right_outlined,
              color: context.moniaryColors.textSecondary,
            ),
            onTap: () async {
              final result = await context.push<CurrencyInfo>(
                '${CurrencyPickerScreen.routePath}?pickOnly=true',
              );
              if (result != null) {
                onSelected(result.code);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _WalletStep extends StatelessWidget {
  const _WalletStep({
    super.key,
    required this.walletNameController,
    required this.amountController,
    required this.currency,
  });

  final TextEditingController walletNameController;
  final TextEditingController amountController;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.profileSurveyWalletTitle,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.profileSurveyWalletBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          TextField(
            controller: walletNameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.profileSurveyWalletName,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.profileSurveyAmountLabel.toUpperCase(),
            style: context.moniaryTypography.metadataStrong,
          ),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: context.l10n.profileSurveyAmountHint,
              suffixText: currency,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.moniaryColors.textPrimary.withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.moniaryColors.primary,
                  width: 1.4,
                ),
              ),
            ),
            style: context.moniaryTypography.displayLarge,
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return MoniaryEditorialCard(
      onTap: onTap,
      borderColor: selected ? colors.primary : colors.outline,
      backgroundColor: selected
          ? colors.primary.withValues(alpha: 0.08)
          : colors.surface.withValues(alpha: 0.78),
      child: Row(
        children: [
          Icon(icon, color: selected ? colors.primary : colors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_outlined
                : Icons.radio_button_unchecked_outlined,
            color: selected ? colors.primary : colors.textDim,
          ),
        ],
      ),
    );
  }
}
