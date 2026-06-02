import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../data/export/file_action_service.dart';

Future<void> openExportFile(
  BuildContext context,
  WidgetRef ref,
  File file,
) async {
  try {
    final opened = await ref.read(fileActionServiceProvider).open(file);
    if (!context.mounted || opened) return;
    _showFileActionError(context, context.l10n.exportNoAppToOpen);
  } catch (e, st) {
    AppLogger.error('Failed to open export file', e, st);
    if (!context.mounted) return;
    _showFileActionError(context, context.l10n.exportNoAppToOpen);
  }
}

Future<void> shareExportFile(
  BuildContext context,
  WidgetRef ref,
  File file,
) async {
  try {
    final shared = await ref.read(fileActionServiceProvider).share(file);
    if (!context.mounted || shared) return;
    _showFileActionError(context, context.l10n.exportNoAppToShare);
  } catch (e, st) {
    AppLogger.error('Failed to share export file', e, st);
    if (!context.mounted) return;
    _showFileActionError(context, context.l10n.exportNoAppToShare);
  }
}

void _showFileActionError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
