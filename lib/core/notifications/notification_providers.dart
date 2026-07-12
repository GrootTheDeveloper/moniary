import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notification_service.dart';

/// Shared instance so scheduling from providers hits the same plugin that
/// [LocalNotificationService.init] configured at startup.
final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService.instance,
);
