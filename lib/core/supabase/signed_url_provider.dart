import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transactions/data/repositories/transaction_repository.dart';

final signedUrlProvider = FutureProvider.family<String, String>((
  ref,
  path,
) async {
  final repo = ref.read(transactionRepositoryProvider);
  return await repo.getSignedImageUrl(path);
});
