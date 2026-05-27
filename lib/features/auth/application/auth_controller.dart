import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);

      await client.auth.signInAnonymously();

      try {
        await client.rpc('initialize_user');
      } on PostgrestException catch (error) {
        // Allow auth to succeed even if the database migration/RPC is not ready yet.
        throw Exception(
          'Dang nhap thanh cong nhung chua goi duoc initialize_user(): ${error.message}',
        );
      }
    });
  }
}
