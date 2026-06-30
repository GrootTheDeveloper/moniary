// Usage: dart run tool/check_privacy_multilingual_guard.dart
// Guards multilingual/l10n compliance and architecture boundaries.
// Exit 0 = all checks pass. Exit 1 = violations found.

import 'dart:convert';
import 'dart:io';

void main() {
  final guard = _Guard();
  guard.run();
  if (guard.failures > 0) {
    stdout.writeln('\n[FAIL] ${guard.failures} check(s) failed.');
    exit(1);
  }
  stdout.writeln('\n[PASS] All checks passed.');
}

class _Guard {
  int failures = 0;

  void _fail(String message) {
    stdout.writeln('[FAIL] $message');
    failures++;
  }

  void _pass(String message) {
    stdout.writeln('[pass] $message');
  }

  void run() {
    _checkArbParity();
    _checkPlaceholderParity();
    _checkGeneratedL10n();
    _checkForbiddenTerms();
    _checkArchitectureBoundaries();
  }

  // ── 1. ARB public key parity ──────────────────────────────────────────────

  void _checkArbParity() {
    final enKeys = _arbPublicKeys('lib/l10n/app_en.arb');
    final viKeys = _arbPublicKeys('lib/l10n/app_vi.arb');

    final enOnly = enKeys.difference(viKeys);
    final viOnly = viKeys.difference(enKeys);

    if (enOnly.isEmpty && viOnly.isEmpty) {
      _pass('ARB public key parity: EN=${enKeys.length} VI=${viKeys.length}');
    } else {
      if (enOnly.isNotEmpty) {
        _fail('Keys in EN only: ${enOnly.toList()..sort()}');
      }
      if (viOnly.isNotEmpty) {
        _fail('Keys in VI only: ${viOnly.toList()..sort()}');
      }
    }
  }

  Set<String> _arbPublicKeys(String path) {
    final content = File(path).readAsStringSync();
    final Map<String, dynamic> arb =
        jsonDecode(content) as Map<String, dynamic>;
    return arb.keys.where((k) => !k.startsWith('@')).toSet();
  }

  // ── 2. Placeholder parity for parameterized keys ──────────────────────────

  void _checkPlaceholderParity() {
    final enArb = _parseArb('lib/l10n/app_en.arb');
    final viArb = _parseArb('lib/l10n/app_vi.arb');
    var mismatch = 0;

    for (final key in enArb.keys.where((k) => !k.startsWith('@'))) {
      final metaKey = '@$key';
      final enMeta = enArb[metaKey] as Map<String, dynamic>?;
      final viMeta = viArb[metaKey] as Map<String, dynamic>?;

      final enPlaceholders =
          (enMeta?['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
          const <String>{};
      final viPlaceholders =
          (viMeta?['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
          const <String>{};

      if (enPlaceholders.isNotEmpty || viPlaceholders.isNotEmpty) {
        final enOnly = enPlaceholders.difference(viPlaceholders);
        final viOnly = viPlaceholders.difference(enPlaceholders);
        if (enOnly.isNotEmpty || viOnly.isNotEmpty) {
          _fail(
            'Placeholder mismatch for "$key": '
            'EN-only=$enOnly VI-only=$viOnly',
          );
          mismatch++;
        }
      }
    }
    if (mismatch == 0) {
      _pass('ARB placeholder parity: no mismatches');
    }
  }

  Map<String, dynamic> _parseArb(String path) {
    final content = File(path).readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  // ── 3. Generated l10n contains all public ARB keys ────────────────────────
  // Conservative: just check the key name appears in the abstract class file.

  void _checkGeneratedL10n() {
    final enKeys = _arbPublicKeys('lib/l10n/app_en.arb');
    final abstractContent = File(
      'lib/l10n/gen_l10n/app_localizations.dart',
    ).readAsStringSync();
    final missing = <String>[];
    for (final key in enKeys) {
      // Each key appears as a getter or method named exactly `key`.
      if (!abstractContent.contains(' $key') &&
          !abstractContent.contains('\n  $key')) {
        missing.add(key);
      }
    }
    if (missing.isEmpty) {
      _pass('Generated l10n contains all ${enKeys.length} public ARB keys');
    } else {
      _fail('Keys missing from generated l10n: $missing');
    }
  }

  // ── 4. Forbidden terms in lib/ ────────────────────────────────────────────

  void _checkForbiddenTerms() {
    _checkPattern(
      pattern: 'formatVnd',
      dirs: ['lib'],
      label: 'Legacy formatVnd helper',
    );
    _checkPattern(
      pattern: 'transactionAmountSuffix',
      dirs: ['lib'],
      label: 'Legacy transactionAmountSuffix key',
    );
    _checkPattern(
      pattern: "'57000'",
      dirs: ['lib'],
      label: 'Hardcoded VND hint 57000',
    );
  }

  void _checkPattern({
    required String pattern,
    required List<String> dirs,
    required String label,
  }) {
    final hits = <String>[];
    for (final dir in dirs) {
      _walkDart(dir, (file) {
        final content = file.readAsStringSync();
        if (content.contains(pattern)) {
          hits.add(file.path);
        }
      });
    }
    if (hits.isEmpty) {
      _pass('No "$pattern" occurrences: $label');
    } else {
      _fail('"$pattern" found in: ${hits.join(', ')} ($label)');
    }
  }

  // ── 5. Architecture boundary violations ───────────────────────────────────

  void _checkArchitectureBoundaries() {
    final restricted = ['lib/features'];
    final forbiddenPatterns = {
      'BuildContext': 'BuildContext in data/domain',
      'context.l10n': 'l10n in data/domain',
      '.l10n': 'l10n extension in data/domain',
      'preferredCurrencyProvider': 'UI provider in data/domain',
    };

    var total = 0;
    for (final base in restricted) {
      _walkDart(base, (file) {
        // Only data/ and domain/ subdirectories
        final rel = file.path.replaceAll('\\', '/');
        if (!rel.contains('/data/') && !rel.contains('/domain/')) return;

        final content = file.readAsStringSync();
        for (final entry in forbiddenPatterns.entries) {
          if (content.contains(entry.key)) {
            _fail('${entry.value} in ${file.path}');
            total++;
          }
        }
      });
    }
    if (total == 0) {
      _pass('Architecture boundaries: no violations in data/domain layers');
    }
  }

  // ── File traversal ────────────────────────────────────────────────────────

  void _walkDart(String dirPath, void Function(File) callback) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Skip build artefacts and generated files
        final norm = entity.path.replaceAll('\\', '/');
        if (norm.contains('/build/') ||
            norm.contains('/.dart_tool/') ||
            norm.contains('/gen_l10n/') ||
            norm.contains('generated_plugin_registrant')) {
          continue;
        }
        callback(entity);
      }
    }
  }
}
