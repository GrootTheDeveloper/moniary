import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/preferences/preferences_bootstrap.dart';
import 'core/supabase/supabase_bootstrap.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: ${e.code}\nError Message: ${e.description}');
  }
  await initializeDateFormatting('vi_VN');
  await bootstrapPreferences();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: MoniaryApp()));
}
