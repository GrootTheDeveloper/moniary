import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/friend_controller.dart';
import '../../domain/friend_qr_payload.dart';
import '../../domain/entities/friend_profile.dart';
import 'friend_invite_accept_screen.dart';

enum _FriendQrMode { myCode, scan }

class FriendQrScreen extends ConsumerStatefulWidget {
  const FriendQrScreen({super.key});

  static const routePath = '/friends/qr';

  @override
  ConsumerState<FriendQrScreen> createState() => _FriendQrScreenState();
}

class _FriendQrScreenState extends ConsumerState<FriendQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  _FriendQrMode _mode = _FriendQrMode.myCode;
  bool _handlingScan = false;
  bool _loadingInvite = false;
  FriendInviteLink? _inviteLink;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.friendQrTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_FriendQrMode>(
                segments: [
                  ButtonSegment(
                    value: _FriendQrMode.myCode,
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: Text(context.l10n.friendQrMyCode),
                  ),
                  ButtonSegment(
                    value: _FriendQrMode.scan,
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    label: Text(context.l10n.friendQrScan),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.single);
                },
              ),
            ),
          ),
          Expanded(
            child: _mode == _FriendQrMode.myCode
                ? _buildMyCode()
                : _buildScanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCode() {
    final invite = _inviteLink;
    if (_loadingInvite) {
      return const Center(child: CircularProgressIndicator());
    }
    if (invite == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2_outlined,
                size: 64,
                color: context.moniaryColors.textDim,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.friendInviteShareDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _createInviteLink,
                icon: const Icon(Icons.qr_code_2_outlined),
                label: Text(context.l10n.friendQrGenerate),
              ),
            ],
          ),
        ),
      );
    }

    final expires = MaterialLocalizations.of(
      context,
    ).formatMediumDate(invite.expiresAt);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: context.l10n.friendQrMyCode,
              child: QrImageView(
                data: invite.link,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: context.moniaryColors.surfaceRaised,
                padding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.friendInviteExpires(expires),
              style: context.moniaryTypography.metadata,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => Share.share(
                    context.l10n.friendInviteShareMessage(invite.link),
                    subject: context.l10n.friendShareInviteLink,
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(context.l10n.friendQrShare),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyInviteLink(invite.link),
                  icon: const Icon(Icons.content_copy_outlined),
                  label: Text(context.l10n.friendQrCopy),
                ),
                TextButton.icon(
                  onPressed: _revokeInviteLink,
                  icon: const Icon(Icons.link_off_outlined),
                  label: Text(context.l10n.friendQrRevoke),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createInviteLink() async {
    setState(() => _loadingInvite = true);
    try {
      final invite = await ref
          .read(friendActionControllerProvider.notifier)
          .createInviteLink();
      if (!mounted) return;
      setState(() => _inviteLink = invite);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _loadingInvite = false);
    }
  }

  Future<void> _copyInviteLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendQrCopied)));
  }

  Future<void> _revokeInviteLink() async {
    final invite = _inviteLink;
    if (invite == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.friendQrRevoke),
        content: Text(context.l10n.friendQrRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.friendQrRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(friendActionControllerProvider.notifier)
          .revokeInviteLink(invite.token);
      if (!mounted) return;
      setState(() => _inviteLink = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.friendQrRevoked)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Widget _buildScanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error) =>
              Center(child: Text(context.l10n.friendQrLoadError)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: context.l10n.friendQrTorch,
                  onPressed: _scannerController.toggleTorch,
                  icon: const Icon(Icons.flashlight_on_outlined),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  tooltip: context.l10n.friendQrSwitchCamera,
                  onPressed: _scannerController.switchCamera,
                  icon: const Icon(Icons.cameraswitch_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingScan) return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (rawValue == null) return;

    _handlingScan = true;
    final token = FriendQrPayload.inviteToken(rawValue);
    await _scannerController.stop();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.friendQrInvalid)));
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
    } else if (mounted) {
      await context.push(FriendInviteAcceptScreen.routeLocation(token));
    }
    _handlingScan = false;
    if (mounted && _mode == _FriendQrMode.scan) {
      await _scannerController.start();
    }
  }
}
