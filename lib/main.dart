import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/preferences/preferences_bootstrap.dart';
import 'core/supabase/supabase_bootstrap.dart';

// Global camera list — initialized once at app start. Low priority refactor.
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras asynchronously to prevent blocking app startup (especially on buggy emulators)
  unawaited(
    availableCameras().then((value) {
      cameras = value;
    }).catchError((e) {
      debugPrint('Error initializing cameras: $e');
    }),
  );

  await initializeDateFormatting('vi_VN');
  AppConstants.assertSupabaseConfig();
  await bootstrapPreferences();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: MoniaryApp()));
}
