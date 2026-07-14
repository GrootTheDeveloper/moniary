import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/friend_controller.dart';
import '../../domain/friend_qr_payload.dart';
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
    final inviteAsync = ref.watch(friendInviteLinkProvider);
    return inviteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(userFriendlyMessage(context, error)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(friendInviteLinkProvider),
                icon: const Icon(Icons.refresh_outlined),
                label: Text(context.l10n.friendQrRetry),
              ),
            ],
          ),
        );
      },
      data: (invite) {
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
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(18),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Share.share(
                    context.l10n.friendInviteShareMessage(invite.link),
                    subject: context.l10n.friendShareInviteLink,
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(context.l10n.friendQrShare),
                ),
              ],
            ),
          ),
        );
      },
    );
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
