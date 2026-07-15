import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

Future<void> bootstrapSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
