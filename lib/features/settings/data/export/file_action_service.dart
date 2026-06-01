import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

final fileActionServiceProvider = Provider<FileActionService>((ref) {
  return const FileActionService();
});

class FileActionService {
  const FileActionService();

  Future<bool> open(File file) async {
    final result = await OpenFilex.open(file.path);
    return result.type == ResultType.done;
  }

  Future<bool> share(File file) async {
    final result = await Share.shareXFiles([XFile(file.path)]);
    return result.status == ShareResultStatus.success;
  }
}
