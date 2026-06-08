import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/application/profile_setup_controller.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../application/account/account_actions_controller.dart';
import 'export/export_data_screen.dart';
import 'import/import_data_screen.dart';
import 'notifications/notification_settings_screen.dart';
import 'privacy/privacy_center_screen.dart';
import 'widgets/delete_account_dialog.dart';

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
                          Icons.lock_outline,
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
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.link),
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

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1521), AppTheme.background, Color(0xFF08111B)],
          ),
        ),
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
                  final name = profile.fullName?.trim().isNotEmpty == true
                      ? profile.fullName!.trim()
                      : context.l10n.profileUserDefault;
                  final email = profile.email?.trim().isNotEmpty == true
                      ? profile.email!.trim()
                      : context.l10n.profileAnonymous;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      _ProfileHeader(
                        title: name,
                        subtitle: email,
                        provider: provider,
                        isAnonymous: isAnonymous,
                      ),
                      const SizedBox(height: 20),
                      if (isAnonymous) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.mint.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.mint.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_outlined,
                                    color: AppTheme.mint,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.profileProtectAccount,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.profileAnonymousWarning,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _showLinkAccountSheet,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.mint,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.profileLinkNow,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _SettingsGroup(
                        title: context.l10n.profileMyData,
                        children: [
                          _SettingsTile(
                            icon: Icons.file_upload_outlined,
                            title: context.l10n.profileImportData,
                            subtitle: context.l10n.profileImportSubtitle,
                            onTap: () =>
                                context.push(ImportDataScreen.routePath),
                          ),
                          _SettingsTile(
                            icon: Icons.file_download_outlined,
                            title: context.l10n.profileExportData,
                            subtitle: context.l10n.profileExportSubtitle,
                            onTap: () =>
                                context.push(ExportDataScreen.routePath),
                          ),
                          _SettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: context.l10n.profilePrivacyCenter,
                            subtitle: context.l10n.profilePrivacySubtitle,
                            onTap: () =>
                                context.push(PrivacyCenterScreen.routePath),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                        title: context.l10n.profileAccount,
                        children: [
                          _SettingsTile(
                            icon: Icons.manage_accounts_outlined,
                            title: context.l10n.profileEditInfo,
                            subtitle: '',
                            onTap: () =>
                                context.push(ProfileSetupScreen.routePath),
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
                            icon: Icons.lock_outline,
                            title: context.l10n.profileChangeTimezone,
                            subtitle: profile.timezone,
                            onTap: () =>
                                context.push(ProfileSetupScreen.routePath),
                          ),
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
                            title: context.l10n.profileDeleteAccount,
                            subtitle: context.l10n.profileDeleteSubtitle,
                            destructive: true,
                            onTap: state.isLoading
                                ? null
                                : () => _confirmDelete(context),
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

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(context.l10n.profileSignOutDialogTitle),
        content: Text(context.l10n.profileSignOutDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text(context.l10n.profileSignOut),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(accountActionsControllerProvider.notifier).deleteAccount();
    if (context.mounted) {
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
  });

  final String title;
  final String subtitle;
  final String provider;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.mint, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                title.isNotEmpty ? title.substring(0, 1).toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAnonymous
                        ? AppTheme.danger.withValues(alpha: 0.12)
                        : AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAnonymous ? AppTheme.danger : AppTheme.success,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAnonymous
                            ? Icons.lock_open_outlined
                            : Icons.verified_user_outlined,
                        size: 14,
                        color: isAnonymous ? AppTheme.danger : AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAnonymous
                            ? context.l10n.profileAnonymousBadge
                            : context.l10n.profileVerifiedBadge(provider),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAnonymous
                              ? AppTheme.danger
                              : AppTheme.success,
                        ),
                      ),
                    ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : AppTheme.mint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: destructive ? AppTheme.danger : Colors.white,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_outlined, color: color),
          ],
        ),
      ),
    );
  }
}
