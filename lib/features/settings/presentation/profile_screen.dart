import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../friends/presentation/screens/friends_screen.dart';
import '../../journal/presentation/journal_collections_screen.dart';
import '../../journal/presentation/monthly_recap_screen.dart';
import '../../journal/presentation/recording_streak_screen.dart';
import '../../profile/application/profile_setup_controller.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../application/account/account_actions_controller.dart';
import '../application/privacy_controller.dart';
import 'export/export_data_screen.dart';
import 'import/import_data_screen.dart';
import 'notifications/notification_settings_screen.dart';
import 'privacy/privacy_center_screen.dart';
import 'privacy/privacy_contact_screen.dart';
import 'settings_home_screen.dart';
import 'account/delete_account_screen.dart';
import 'support/help_center_screen.dart';
import 'widgets/settings_action_tile.dart';
import 'widgets/settings_group_card.dart';
import 'widgets/settings_status_chip.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLinkingLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setLinkingLoading(bool value, VoidCallback refreshSheet) {
    if (!mounted) return;
    setState(() => _isLinkingLoading = value);
    refreshSheet();
  }

  Future<bool> _linkEmailAccount(VoidCallback refreshSheet) async {
    if (!_formKey.currentState!.validate()) return false;

    _setLinkingLoading(true, refreshSheet);
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .linkEmailAccount(email: email, password: password);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileLinkSuccess),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      ref.invalidate(currentProfileProvider);
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to link email account from profile', e, st);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage(context, e)),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return false;
    } finally {
      _setLinkingLoading(false, refreshSheet);
    }
  }

  Future<void> _linkGoogleAccount(VoidCallback refreshSheet) async {
    _setLinkingLoading(true, refreshSheet);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authControllerProvider.notifier).linkGoogleAccount();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileLinkGoogleBrowser),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to link Google account from profile', e, st);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.profileLinkGoogleError(
                userFriendlyMessage(context, e),
              ),
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      _setLinkingLoading(false, refreshSheet);
    }
  }

  Future<void> _linkAppleAccount(VoidCallback refreshSheet) async {
    _setLinkingLoading(true, refreshSheet);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authControllerProvider.notifier).linkAppleAccount();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileLinkAppleBrowser),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to link Apple account from profile', e, st);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.profileLinkAppleError(
                userFriendlyMessage(context, e),
              ),
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      _setLinkingLoading(false, refreshSheet);
    }
  }

  void _showLinkAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refreshSheet() {
              if (context.mounted) {
                setSheetState(() {});
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.profileLinkAccountTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.profileLinkAccountSubtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: context.l10n.loginEmail,
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return context.l10n.validationEmailRequired;
                        }
                        if (!val.contains('@')) {
                          return context.l10n.validationEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: context.l10n.profileNewPassword,
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return context.l10n.validationPasswordMinLength(6);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isLinkingLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: AppTheme.mint,
                          ),
                        ),
                      )
                    else ...[
                      FilledButton.icon(
                        onPressed: () async {
                          final linked = await _linkEmailAccount(refreshSheet);
                          if (linked && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.mint,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.link_outlined),
                        label: Text(
                          context.l10n.profileLinkEmail,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _linkGoogleAccount(refreshSheet);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: AppTheme.outline),
                        ),
                        icon: const Icon(
                          Icons.g_mobiledata,
                          size: 28,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.l10n.profileLinkGoogle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _linkAppleAccount(refreshSheet);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: AppTheme.outline),
                        ),
                        icon: const Icon(
                          Icons.apple,
                          size: 28,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.l10n.profileLinkApple,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final state = ref.watch(accountActionsControllerProvider);
    final privacyState = ref.watch(privacyControllerProvider);
    final requestHistory = ref.watch(privacyRequestHistoryProvider);
    final isGuest = ref.watch(guestModeEnabledProvider);
    final locale = ref.watch(preferredLocaleProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: ColoredBox(
        color: colors.background,
        child: SafeArea(
          child: Stack(
            children: [
              profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return Center(child: Text(context.l10n.errorGeneric));
                  }

                  final provider = profile.loginProvider;
                  final isAnonymous = provider == 'anonymous';
                  final accountMode = _ProfileAccountMode.from(
                    isGuest: isGuest,
                    provider: provider,
                  );
                  final name = profile.fullName?.trim().isNotEmpty == true
                      ? profile.fullName!.trim()
                      : context.l10n.profileUserDefault;
                  final email = profile.email?.trim().isNotEmpty == true
                      ? profile.email!.trim()
                      : context.l10n.profileAnonymous;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
                    children: [
                      _ProfileHeader(
                        title: name,
                        subtitle: email,
                        provider: provider,
                        isAnonymous: isAnonymous,
                        avatarUrl: profile.avatarUrl,
                        onTap: () => context.push(
                          '${ProfileSetupScreen.routePath}?mode=edit',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ProfileQuickActions(
                        onFriends: () => context.push(FriendsScreen.routePath),
                        onExport: () =>
                            context.push(ExportDataScreen.routePath),
                        onSettings: () =>
                            context.push(SettingsHomeScreen.routePath),
                      ),
                      const SizedBox(height: 28),
                      _SettingsGroup(
                        title: context.l10n.profileMoniarySetup,
                        children: [
                          _SettingsTile(
                            icon: Icons.file_download_outlined,
                            title: context.l10n.profileImportData,
                            subtitle: context.l10n.profileImportSubtitle,
                            onTap: () =>
                                context.push(ImportDataScreen.routePath),
                          ),
                          _SettingsTile(
                            icon: Icons.file_upload_outlined,
                            title: context.l10n.exportDataTitle,
                            subtitle: context.l10n.profileExportSubtitle,
                            onTap: () =>
                                context.push(ExportDataScreen.routePath),
                          ),
                          _SettingsTile(
                            icon: Icons.star_outlined,
                            title: context.l10n.starredTransactionsTitle,
                            subtitle: '',
                            onTap: () => context.push('/starred-transactions'),
                          ),
                          _SettingsTile(
                            icon: Icons.auto_stories_outlined,
                            title: context.l10n.journalRecapTitle,
                            subtitle: '',
                            onTap: () {
                              final now = DateTime.now();
                              context.push(
                                MonthlyRecapScreen.routePath,
                                extra: DateTime(now.year, now.month),
                              );
                            },
                          ),
                          _SettingsTile(
                            icon: Icons.collections_bookmark_outlined,
                            title: context.l10n.journalCollectionsTitle,
                            subtitle: '',
                            onTap: () => context.push(
                              JournalCollectionsScreen.routePath,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.local_fire_department_outlined,
                            title: context.l10n.journalStreakTitle,
                            subtitle: '',
                            onTap: () =>
                                context.push(RecordingStreakScreen.routePath),
                          ),
                          _SettingsTile(
                            icon: Icons.auto_awesome_outlined,
                            title: context.l10n.profileHowMoniaryWorksTitle,
                            subtitle:
                                context.l10n.profileHowMoniaryWorksSubtitle,
                            onTap: _showMoniarySetupSheet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SettingsGroup(
                        title: context.l10n.profileGeneralSection,
                        children: [
                          _SettingsTile(
                            icon: Icons.person_outlined,
                            title: context.l10n.editProfileTitle,
                            subtitle: email,
                            onTap: () => _showEditProfileSheet(
                              name: name,
                              email: email,
                              provider: provider,
                              isAnonymous: isAnonymous,
                              avatarUrl: profile.avatarUrl,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.notifications_outlined,
                            title: context.l10n.notificationSettings,
                            subtitle: '',
                            onTap: () => context.push(
                              NotificationSettingsScreen.routePath,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.language_outlined,
                            title: context.l10n.profileLanguageLabel,
                            subtitle: locale.languageCode == 'en'
                                ? context.l10n.profileLanguageEn
                                : context.l10n.profileLanguageVi,
                            onTap: () => _showLanguageSheet(locale.languageCode),
                          ),
                          _SettingsTile(
                            icon: Icons.schedule_outlined,
                            title: context.l10n.profileChangeTimezone,
                            subtitle: profile.timezone,
                            onTap: () =>
                                context.push(ProfileSetupScreen.routePath),
                          ),
                          if (accountMode.needsAccountProtectionCard)
                            _AccountModeBanner(
                              mode: accountMode,
                              onAction: accountMode == _ProfileAccountMode.guest
                                  ? () {
                                      _switchFromGuestToLogin();
                                    }
                                  : _showLinkAccountSheet,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SettingsGroup(
                        title: context.l10n.profileSupportSection,
                        children: [
                          _SettingsTile(
                            icon: Icons.help_outlined,
                            title: context.l10n.helpCenterTitle,
                            subtitle: context.l10n.privacyHelpCenterSubtitle,
                            onTap: () =>
                                context.push(HelpCenterScreen.routePath),
                          ),
                          _SettingsTile(
                            icon: Icons.support_agent_outlined,
                            title: context.l10n.privacyRequestsTitle,
                            subtitle: context.l10n.privacyRequestsSubtitle,
                            status: requestHistory.whenOrNull(
                              data: (items) => SettingsStatusChip(
                                label: context.l10n.privacyRequestCount(
                                  items.length,
                                ),
                                tone: items.isEmpty
                                    ? SettingsStatusTone.neutral
                                    : SettingsStatusTone.info,
                              ),
                            ),
                            onTap: () =>
                                context.push(PrivacyContactScreen.routePath),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SettingsGroup(
                        title: context.l10n.profilePrivacySafetySection,
                        children: [
                          _SettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: context.l10n.privacyGroupPrivacyTermsTitle,
                            subtitle:
                                context.l10n.privacyGroupPrivacyTermsSubtitle,
                            onTap: () => context.push(
                              PrivacyCenterScreen.location(
                                PrivacyCenterGroup.privacyTerms,
                              ),
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.verified_user_outlined,
                            title: context.l10n.privacyGroupDataSafetyTitle,
                            subtitle:
                                context.l10n.privacyGroupDataSafetySubtitle,
                            status: SettingsStatusChip(
                              label: privacyState.isAppLocked
                                  ? context.l10n.privacyStatusProtected
                                  : context.l10n.privacyStatusReview,
                              tone: privacyState.isAppLocked
                                  ? SettingsStatusTone.success
                                  : SettingsStatusTone.warning,
                            ),
                            onTap: () => context.push(
                              PrivacyCenterScreen.location(
                                PrivacyCenterGroup.dataSafety,
                              ),
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.support_agent_outlined,
                            title: context.l10n.privacyGroupHelpRequestsTitle,
                            subtitle:
                                context.l10n.privacyGroupHelpRequestsSubtitle,
                            onTap: () => context.push(
                              PrivacyCenterScreen.location(
                                PrivacyCenterGroup.helpRequests,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SettingsGroup(
                        title: context.l10n.profileDangerZoneSection,
                        children: [
                          _SettingsTile(
                            icon: Icons.logout_outlined,
                            title: context.l10n.profileSignOut,
                            subtitle: context.l10n.profileSignOutSubtitle,
                            onTap: state.isLoading
                                ? null
                                : () => _signOut(context),
                          ),
                          _SettingsTile(
                            icon: Icons.delete_forever_outlined,
                            title: isGuest
                                ? context.l10n.deleteGuestDataTitle
                                : context.l10n.profileDeleteAccount,
                            subtitle: isGuest
                                ? context.l10n.deleteGuestDataBody
                                : context.l10n.profileDeleteSubtitle,
                            destructive: true,
                            onTap: state.isLoading
                                ? null
                                : () => context.push(
                                    DeleteAccountScreen.routePath,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) {
                  AppLogger.error(
                    'Failed to load profile screen',
                    error,
                    stackTrace,
                  );
                  return Center(
                    child: Text(userFriendlyMessage(context, error)),
                  );
                },
              ),
              if (state.isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoniarySetupSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.profileHowMoniaryWorksTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  _SetupStep(
                    icon: Icons.account_balance_wallet_outlined,
                    title: context.l10n.profileSetupGuideWalletTitle,
                    body: context.l10n.profileSetupGuideWalletBody,
                  ),
                  _SetupStep(
                    icon: Icons.camera_alt_outlined,
                    title: context.l10n.profileSetupGuideTransactionTitle,
                    body: context.l10n.profileSetupGuideTransactionBody,
                  ),
                  _SetupStep(
                    icon: Icons.calendar_month_outlined,
                    title: context.l10n.profileSetupGuideReviewTitle,
                    body: context.l10n.profileSetupGuideReviewBody,
                  ),
                  _SetupStep(
                    icon: Icons.ios_share_outlined,
                    title: context.l10n.profileSetupGuideExportTitle,
                    body: context.l10n.profileSetupGuideExportBody,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(CalendarScreen.routePath);
                    },
                    child: Text(context.l10n.calendarTitle),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet({
    required String name,
    required String email,
    required String provider,
    required bool isAnonymous,
    required String? avatarUrl,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                title: name,
                subtitle: email,
                provider: provider,
                isAnonymous: isAnonymous,
                avatarUrl: avatarUrl,
                onTap: () {},
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('${ProfileSetupScreen.routePath}?mode=edit');
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.editProfileTitle),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSheet(String currentCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.profileLanguageLabel,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: currentCode,
                onChanged: (v) {
                  if (v == null) return;
                  ref
                      .read(preferredLocaleProvider.notifier)
                      .setLocale(Locale(v));
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'vi',
                      title: Text(context.l10n.profileLanguageVi),
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      title: Text(context.l10n.profileLanguageEn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(context.l10n.profileSignOutDialogTitle),
        content: Text(context.l10n.profileSignOutDialogMessage),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                child: Text(context.l10n.commonConfirm),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.profileCancel),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.go(LoginScreen.routePath);
      }
    }
  }

  Future<void> _switchFromGuestToLogin() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go(LoginScreen.routePath);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.title,
    required this.subtitle,
    required this.provider,
    required this.isAnonymous,
    required this.avatarUrl,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String provider;
  final bool isAnonymous;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.textPrimary.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: avatarUrl?.isNotEmpty == true
                  ? SupabaseImage(
                      imagePath: avatarUrl,
                      width: 76,
                      height: 76,
                      borderRadius: BorderRadius.circular(23),
                    )
                  : Center(
                      child: Text(
                        title.isNotEmpty
                            ? title.substring(0, 1).toUpperCase()
                            : '',
                        style: context.moniaryTypography.displayMedium.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.moniaryTypography.displayMedium),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.moniaryTypography.metadata,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        isAnonymous
                            ? Icons.lock_open_outlined
                            : Icons.verified_user_outlined,
                        size: 15,
                        color: isAnonymous ? colors.danger : colors.success,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          (isAnonymous
                                  ? context.l10n.profileAnonymousBadge
                                  : context.l10n.profileVerifiedBadge(provider))
                              .toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: context.moniaryTypography.metadataStrong
                              .copyWith(
                                color: isAnonymous
                                    ? colors.danger
                                    : colors.success,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 19, color: colors.textDim),
          ],
        ),
      ),
    );
  }
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({
    required this.onFriends,
    required this.onExport,
    required this.onSettings,
  });

  final VoidCallback onFriends;
  final VoidCallback onExport;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.people_outlined,
            label: context.l10n.friendsTitle,
            onTap: onFriends,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.file_upload_outlined,
            label: context.l10n.exportDataTitle,
            onTap: onExport,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.settings_outlined,
            label: context.l10n.settingsTitle,
            onTap: onSettings,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.moniaryTypography.metadataStrong,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.mint, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProfileAccountMode {
  guest,
  supabaseAnonymous,
  authenticated;

  static _ProfileAccountMode from({
    required bool isGuest,
    required String provider,
  }) {
    if (isGuest) return _ProfileAccountMode.guest;
    if (provider == 'anonymous') return _ProfileAccountMode.supabaseAnonymous;
    return _ProfileAccountMode.authenticated;
  }

  bool get needsAccountProtectionCard =>
      this != _ProfileAccountMode.authenticated;

  Color get accentColor {
    return switch (this) {
      _ProfileAccountMode.guest => AppTheme.amber,
      _ProfileAccountMode.supabaseAnonymous => AppTheme.mint,
      _ProfileAccountMode.authenticated => AppTheme.success,
    };
  }

  IconData get icon {
    return switch (this) {
      _ProfileAccountMode.guest => Icons.person_outlined,
      _ProfileAccountMode.supabaseAnonymous => Icons.warning_amber_outlined,
      _ProfileAccountMode.authenticated => Icons.verified_user_outlined,
    };
  }

  String title(BuildContext context) {
    return switch (this) {
      _ProfileAccountMode.guest => context.l10n.profileAnonymous,
      _ProfileAccountMode.supabaseAnonymous =>
        context.l10n.profileProtectAccount,
      _ProfileAccountMode.authenticated => context.l10n.profileAccount,
    };
  }

  String body(BuildContext context) {
    return switch (this) {
      _ProfileAccountMode.guest => context.l10n.profileAnonymousWarning,
      _ProfileAccountMode.supabaseAnonymous =>
        context.l10n.profileLinkAccountSubtitle,
      _ProfileAccountMode.authenticated => '',
    };
  }

  String actionLabel(BuildContext context) {
    return switch (this) {
      _ProfileAccountMode.guest => context.l10n.loginSignIn,
      _ProfileAccountMode.supabaseAnonymous => context.l10n.profileLinkNow,
      _ProfileAccountMode.authenticated => context.l10n.profileAccount,
    };
  }
}

class _AccountModeBanner extends StatelessWidget {
  const _AccountModeBanner({required this.mode, required this.onAction});

  final _ProfileAccountMode mode;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final accent = mode.accentColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(mode.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.title(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  mode.body(context),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.link_outlined),
                    label: Text(mode.actionLabel(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SettingsGroupCard(title: title, children: children);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return SettingsActionTile(
      grouped: true,
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      destructive: destructive,
      status: status,
    );
  }
}
