import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transactions/data/repositories/transaction_repository.dart';

final signedUrlProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  path,
) async {
  final keepAlive = ref.keepAlive();
  final expiryTimer = Timer(const Duration(minutes: 50), ref.invalidateSelf);
  ref.onDispose(() {
    expiryTimer.cancel();
    keepAlive.close();
  });
  final repo = ref.read(transactionRepositoryProvider);
  return await repo.getSignedImageUrl(path);
});
