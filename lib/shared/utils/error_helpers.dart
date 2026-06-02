import 'package:flutter/widgets.dart';
import '../../core/supabase/app_exception.dart';
import '../../l10n/l10n_extension.dart';

/// Returns a user-friendly Vietnamese message for any error.
/// Use this instead of `error.toString()` in SnackBars.
String userFriendlyMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is AppException) {
    switch (error.code) {
      case 'AUTH_REQUIRED':
        return l10n.errorNotLoggedIn;
    }

    switch (error.message) {
      case 'errorConnection':
        return l10n.errorConnection;
      case 'errorGeneric':
        return l10n.errorGeneric;
    }

    return l10n.errorGeneric;
  }
  return l10n.errorGeneric;
}
