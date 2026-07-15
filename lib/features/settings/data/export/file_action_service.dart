import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/utils/app_logger.dart';

final fileActionServiceProvider = Provider<FileActionService>((ref) {
  return const FileActionService();
});

class FileActionService {
  const FileActionService();

  Future<bool> open(File file) async {
    try {
      if (!file.existsSync()) {
        AppLogger.error('FileActionService: File does not exist at ${file.path}');
        return false;
      }
      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done;
    } catch (e, st) {
      AppLogger.error('FileActionService: Failed to open file', e, st);
      return false;
    }
  }

  Future<bool> share(File file) async {
    try {
      if (!file.existsSync()) {
        AppLogger.error('FileActionService: File does not exist at ${file.path}');
        return false;
      }
      final result = await Share.shareXFiles([XFile(file.path)]);
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e, st) {
      AppLogger.error('FileActionService: Failed to share file', e, st);
      return false;
    }
  }
}
