import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android host activity supports local_auth biometric prompts', () {
    final source = File(
      'android/app/src/main/kotlin/com/moniary/moniary/MainActivity.kt',
    ).readAsStringSync();

    expect(
      source,
      contains('import io.flutter.embedding.android.FlutterFragmentActivity'),
    );
    expect(source, contains('class MainActivity : FlutterFragmentActivity()'));
  });

  test('Android launch and normal themes are AppCompat themes', () {
    const styleFiles = <String>[
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
      'android/app/src/main/res/values-v31/styles.xml',
    ];

    for (final path in styleFiles) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains(
          '<style name="LaunchTheme" '
          'parent="Theme.AppCompat.Light.NoActionBar">',
        ),
        reason: '$path must keep local_auth compatible at app launch.',
      );
      expect(
        source,
        contains(
          '<style name="NormalTheme" '
          'parent="Theme.AppCompat.Light.NoActionBar">',
        ),
        reason: '$path must remain compatible after Flutter starts.',
      );
    }
  });

  test('Android manifest declares biometric permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.USE_BIOMETRIC'));
  });
}
