import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

Future<void> bootstrapSupabase() async {
  if (!AppConstants.hasSupabaseConfig) {
    debugPrint('Supabase config is missing. App will run in mock mode.');
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIiwiaWF0IjoxNTk4ODgzMDAwLCJleHAiOjE5MDQ0NTcwMDB9.placeholder',
    );
    return;
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
