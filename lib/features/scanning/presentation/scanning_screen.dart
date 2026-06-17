import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/l10n_model_extensions.dart';
import '../../transactions/domain/models/transaction_mutation_result.dart';
import '../../transactions/presentation/camera/camera_screen.dart';
import '../application/scanning_controller.dart';
import 'ocr_review_screen.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({this.initialImagePath, super.key});

  static const routePath = '/scanning';

  final String? initialImagePath;

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen> {
  @override
  void initState() {
    super.initState();
    final initialImagePath = widget.initialImagePath;
    if (initialImagePath != null && initialImagePath.trim().isNotEmpty) {
      Future<void>.microtask(() {
        if (mounted) {
          ref
              .read(scanningControllerProvider.notifier)
              .selectImage(initialImagePath);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanningControllerProvider);
    final busy = state.status == ScanningStatus.scanning;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ReceiptPreview(
            imagePath: state.imagePath,
            onClear: busy
                ? null
                : () => ref
                      .read(scanningControllerProvider.notifier)
                      .clearImage(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _pickImage(ref, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(context.l10n.scanTakePhoto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _pickImage(ref, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.l10n.scanChooseGallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (busy)
            _StatusCard(
              icon: const CircularProgressIndicator(color: AppTheme.mint),
              text: context.l10n.scanExtracting,
            )
          else if (state.status == ScanningStatus.failure)
            _StatusCard(
              icon: const Icon(
                Icons.error_outline,
                color: AppTheme.danger,
                size: 30,
              ),
              text:
                  state.errorType?.getLabel(context) ?? context.l10n.scanFailed,
            )
          else if (state.status == ScanningStatus.success)
            _StatusCard(
              icon: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.success,
                size: 30,
              ),
              text: context.l10n.scanSuccessMessage,
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: state.imagePath == null || busy
                ? null
                : () => _extract(context, ref),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(
              busy ? context.l10n.scanScanning : context.l10n.scanExtractButton,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: busy ? null : () => _openManualEntry(context),
            icon: const Icon(Icons.edit_note_outlined),
            label: Text(context.l10n.scanManualEntry),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (file != null) {
        ref.read(scanningControllerProvider.notifier).selectImage(file.path);
      }
    } catch (e, st) {
      AppLogger.error('Failed to pick image', e, st);
      ref.read(scanningControllerProvider.notifier).setImageError();
    }
  }

  Future<void> _extract(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(scanningControllerProvider.notifier)
        .extract();
    final imagePath = ref.read(scanningControllerProvider).imagePath;
    if (result == null || imagePath == null || !context.mounted) {
      return;
    }

    final mutation = await context.push<TransactionMutationResult>(
      OcrReviewScreen.routePath,
      extra: OcrReviewArgs(result: result, imagePath: imagePath),
    );
    if (mutation != null && context.mounted) {
      context.pop(mutation);
    }
  }

  Future<void> _openManualEntry(BuildContext context) async {
    final mutation = await context.push<TransactionMutationResult>(
      CameraScreen.routePath,
    );
    if (mutation != null && context.mounted) {
      context.pop(mutation);
    }
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.imagePath, required this.onClear});

  final String? imagePath;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
      ),
      child: imagePath == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppTheme.mint,
                  size: 66,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.scanNoReceipt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.scanNoReceiptSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Text(context.l10n.scanImageError)),
                  ),
                ),
                if (onClear != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filledTonal(
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(width: 32, height: 32, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
