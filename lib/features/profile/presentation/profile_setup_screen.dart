import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../features/calendar/presentation/month/calendar_screen.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../auth/presentation/login_screen.dart';
import '../application/profile_setup_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  static const routePath = '/profile-setup';

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _currencies = const ['VND', 'USD', 'EUR'];
  String _currency = 'VND';

  @override
  void initState() {
    super.initState();
    _currency = ref.read(preferredCurrencyProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileSetupControllerProvider);
    final isLoading = profileAsync.isLoading;

    profileAsync.whenData((profile) {
      final currentName = profile?.fullName?.trim() ?? '';
      if (_nameController.text.isEmpty &&
          currentName.isNotEmpty &&
          currentName.toLowerCase() != 'guest') {
        _nameController.text = currentName;
      }
    });

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(LoginScreen.routePath);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_outlined),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Text(
                        context.l10n.profileSetupTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.profileSetupSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF68E5D8), AppTheme.mint],
                              ),
                            ),
                            child: const Icon(
                              Icons.face_outlined,
                              size: 84,
                              color: Color(0xFF10333B),
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.mint,
                              border: Border.all(
                                color: AppTheme.background,
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  context.l10n.profileSetupDisplayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: context.l10n.profileSetupDisplayNameHint,
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.profileSetupCurrency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(),
                  items: _currencies
                      .map(
                        (currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currency = value);
                  },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: Text(
                    isLoading
                        ? context.l10n.commonSaving
                        : context.l10n.profileSetupStart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.profileSetupNameRequired)),
      );
      return;
    }

    try {
      await ref.read(preferredCurrencyProvider.notifier).setCurrency(_currency);
      await ref
          .read(profileSetupControllerProvider.notifier)
          .saveProfile(
            fullName: name,
            timezone: 'Asia/Ho_Chi_Minh', // TODO: detect timezone from device
          );
      if (!mounted) return;
      context.go(CalendarScreen.routePath);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}
