import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/preferences/preferences_bootstrap.dart';
import 'core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Dart Error: $error');
    return true;
  };

  await initializeDateFormatting();
  AppConstants.assertSupabaseConfig();
  await bootstrapPreferences();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: MoniaryApp()));
}
