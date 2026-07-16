import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

Future<void> bootstrapSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    // Keep compatibility with the committed 2.12.x lock; publishableKey was
    // introduced in a later supabase_flutter release.
    // ignore: deprecated_member_use
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
