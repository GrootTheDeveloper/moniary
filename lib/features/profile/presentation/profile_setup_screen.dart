import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../features/calendar/presentation/month/calendar_screen.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../auth/presentation/login_screen.dart';
import '../application/profile_setup_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({this.isEditMode = false, super.key});

  static const routePath = '/profile-setup';
  final bool isEditMode;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currencies = const ['VND', 'USD', 'EUR'];
  String _currency = 'VND';
  String? _avatarPath;
  bool _avatarPicked = false;

  @override
  void initState() {
    super.initState();
    _currency = ref.read(preferredCurrencyProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileSetupControllerProvider);
    final isLoading = profileAsync.isLoading;
    final isEditMode = widget.isEditMode;

    profileAsync.whenData((profile) {
      final profileName = profile?.fullName?.trim() ?? '';
      if (_nameController.text.isEmpty &&
          profileName.isNotEmpty &&
          profileName.toLowerCase() != 'guest') {
        _nameController.text = profileName;
      }

      final profileEmail = profile?.email?.trim();
      final linkedEmail =
          profile?.loginProvider != 'anonymous' &&
              profileEmail?.isNotEmpty == true
          ? profileEmail!
          : '';
      if (_emailController.text != linkedEmail) {
        _emailController.text = linkedEmail;
      }

      final username = profile?.username?.trim() ?? '';
      if (_usernameController.text.isEmpty && username.isNotEmpty) {
        _usernameController.text = username;
      }

      if (!_avatarPicked && _avatarPath == null) {
        _avatarPath = profile?.avatarUrl;
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AuroraBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomPadding =
                  MediaQuery.of(context).viewInsets.bottom + 20;
              final minHeight = constraints.maxHeight - 12 - bottomPadding;
              const avatarSize = 128.0;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minHeight > 0 ? minHeight : 0,
                  ),
                  child: IntrinsicHeight(
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
                        const SizedBox(height: 4),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                isEditMode
                                    ? '${context.l10n.commonEdit} ${context.l10n.profileTitle}'
                                    : context.l10n.profileSetupTitle,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              if (!isEditMode) ...[
                                const SizedBox(height: 6),
                                Text(
                                  context.l10n.profileSetupSubtitle,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                              const SizedBox(height: 22),
                              GestureDetector(
                                onTap: _pickAvatar,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: avatarSize,
                                      height: avatarSize,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppTheme.mintTeal,
                                            AppTheme.mint,
                                          ],
                                        ),
                                      ),
                                      child: _avatarPath?.isNotEmpty == true
                                          ? SupabaseImage(
                                              imagePath: _avatarPath,
                                              width: avatarSize,
                                              height: avatarSize,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    avatarSize / 2,
                                                  ),
                                              fallbackIcon:
                                                  Icons.face_outlined,
                                            )
                                          : const Icon(
                                              Icons.face_outlined,
                                              size: 76,
                                              color: AppTheme.mintTealDark,
                                            ),
                                    ),
                                    Container(
                                      width: 46,
                                      height: 46,
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.groupUsernameLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            hintText: context.l10n.profileUsernameHint,
                            prefixIcon: const Icon(
                              Icons.alternate_email_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.loginEmail,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: context.l10n.loginEmail,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: Text(
                            isLoading
                                ? context.l10n.commonSaving
                                : (isEditMode
                                      ? context.l10n.commonSave
                                      : context.l10n.profileSetupStart),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
    final username = _usernameController.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(username)) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.profileUsernameInvalid)),
      );
      return;
    }

    try {
      await ref.read(preferredCurrencyProvider.notifier).setCurrency(_currency);
      await ref
          .read(profileSetupControllerProvider.notifier)
          .saveProfile(
            fullName: name,
            username: username,
            timezone: 'Asia/Ho_Chi_Minh', // TODO: detect timezone from device
            avatarImagePath: _avatarPicked ? _avatarPath : null,
          );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(CalendarScreen.routePath);
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      setState(() {
        _avatarPath = image.path;
        _avatarPicked = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}
