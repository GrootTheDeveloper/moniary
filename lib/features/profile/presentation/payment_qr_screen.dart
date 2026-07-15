import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../application/profile_setup_controller.dart';
import '../domain/user_profile.dart';

class PaymentQrRouteArgs {
  const PaymentQrRouteArgs({required this.imagePath, required this.name});

  final String? imagePath;
  final String name;
}

class PaymentQrScreen extends ConsumerStatefulWidget {
  const PaymentQrScreen({this.member, super.key});

  static const routePath = '/payment-qr';

  final PaymentQrRouteArgs? member;

  @override
  ConsumerState<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends ConsumerState<PaymentQrScreen> {
  final _picker = ImagePicker();

  bool get _isOwnQr => widget.member == null;

  @override
  Widget build(BuildContext context) {
    final profileAsync = _isOwnQr
        ? ref.watch(paymentQrControllerProvider)
        : const AsyncValue<UserProfile?>.data(null);
    final profile = _isOwnQr ? profileAsync.asData?.value : null;
    final imagePath = widget.member?.imagePath ?? profile?.paymentQrPath;
    final name = widget.member?.name ?? context.l10n.paymentQrMyTitle;
    final actionState = ref.watch(paymentQrControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(userFriendlyMessage(context, error)),
          ),
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          children: [
            Text(
              _isOwnQr
                  ? context.l10n.paymentQrDescription
                  : context.l10n.paymentQrMemberDescription(name),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Container(
              constraints: const BoxConstraints(minHeight: 300),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.moniaryColors.outline),
              ),
              child: imagePath == null || imagePath.isEmpty
                  ? _EmptyQr(isOwner: _isOwnQr)
                  : SupabaseImage(
                      imagePath: imagePath,
                      fit: BoxFit.contain,
                      fallbackBuilder: (_) => _EmptyQr(isOwner: _isOwnQr),
                    ),
            ),
            if (_isOwnQr) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: actionState.isLoading ? null : _pickAndSave,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  imagePath == null
                      ? context.l10n.paymentQrAdd
                      : context.l10n.paymentQrReplace,
                ),
              ),
              if (imagePath != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: actionState.isLoading ? null : _clear,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.paymentQrRemove),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.l10n.paymentQrPrivacyNote,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.moniaryColors.textDim),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSave() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    try {
      await ref.read(paymentQrControllerProvider.notifier).save(image.path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.paymentQrSaved)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _clear() async {
    try {
      await ref.read(paymentQrControllerProvider.notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.paymentQrRemoved)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _EmptyQr extends StatelessWidget {
  const _EmptyQr({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 260,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_2_outlined,
            size: 58,
            color: context.moniaryColors.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            isOwner
                ? context.l10n.paymentQrEmptyOwner
                : context.l10n.paymentQrEmptyMember,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
