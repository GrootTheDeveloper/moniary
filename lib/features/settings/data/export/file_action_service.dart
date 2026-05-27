import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fileActionServiceProvider = Provider<FileActionService>((ref) {
  return const FileActionService();
});

class FileActionService {
  const FileActionService();

  static const _channel = MethodChannel('moniary/file_actions');

  Future<bool> open(File file) async {
    if (!Platform.isAndroid) {
      return false;
    }

    final opened = await _channel.invokeMethod<bool>('openFile', {
      'path': file.path,
    });
    return opened ?? false;
  }

  Future<bool> share(File file) async {
    if (!Platform.isAndroid) {
      return false;
    }

    final shared = await _channel.invokeMethod<bool>('shareFile', {
      'path': file.path,
    });
    return shared ?? false;
  }
}
