import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences/preferences_providers.dart';
import 'currency_formatter.dart';

/// Convenience for formatting amounts with the user's preferred currency and
/// locale from a widget build method, without repeating both provider reads
/// at every call site.
extension CurrencyFormatting on WidgetRef {
  String formatAmount(num amount) {
    return formatCurrency(
      amount,
      currencyCode: watch(preferredCurrencyProvider),
      locale: watch(preferredLocaleProvider),
    );
  }

  String get currencySymbol {
    return currencySymbolFor(
      currencyCode: watch(preferredCurrencyProvider),
      locale: watch(preferredLocaleProvider),
    );
  }
}
