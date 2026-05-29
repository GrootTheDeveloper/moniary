import 'package:flutter/widgets.dart';
import '../../core/supabase/app_exception.dart';
import '../../l10n/l10n_extension.dart';

/// Returns a user-friendly Vietnamese message for any error.
/// Use this instead of `error.toString()` in SnackBars.
String userFriendlyMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is AppException) {
    if (error.message == 'errorConnection') return l10n.errorConnection;
    return error.message;
  }
  return l10n.errorGeneric;
}
