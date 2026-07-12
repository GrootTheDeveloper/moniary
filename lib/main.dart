import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/preferences/preferences_bootstrap.dart';
import 'core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Dart Error: $error');
    return true;
  };

  await initializeDateFormatting(AppConstants.defaultLocale);
  AppConstants.assertSupabaseConfig();
  await bootstrapPreferences();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: MoniaryApp()));
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in const <(String, String)>[
      ('Manrope', 'assets/fonts/OFL-Manrope.txt'),
      ('Instrument Serif', 'assets/fonts/OFL-InstrumentSerif.txt'),
      ('JetBrains Mono', 'assets/fonts/OFL-JetBrainsMono.txt'),
    ]) {
      final license = await rootBundle.loadString(entry.$2);
      yield LicenseEntryWithLineBreaks(<String>[entry.$1], license);
    }
  });
}
