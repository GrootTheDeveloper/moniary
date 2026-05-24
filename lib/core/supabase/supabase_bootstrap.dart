import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

Future<void> bootstrapSupabase() async {
  if (!AppConstants.hasSupabaseConfig) {
    debugPrint('Supabase config is missing. App will run in shell mode.');
    return;
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
}
