import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/notification_delivery_preferences_repository_impl.dart';
import '../domain/entities/notification_delivery_preferences.dart';

final notificationDeliveryPreferencesControllerProvider =
    AsyncNotifierProvider<
      NotificationDeliveryPreferencesController,
      NotificationDeliveryPreferences
    >(NotificationDeliveryPreferencesController.new);

class NotificationDeliveryPreferencesController
    extends AsyncNotifier<NotificationDeliveryPreferences> {
  @override
  FutureOr<NotificationDeliveryPreferences> build() {
    return ref
        .read(notificationDeliveryPreferencesRepositoryProvider)
        .getPreferences();
  }

  Future<void> setPushEnabled(bool enabled) {
    return _update(state.value?.copyWith(pushEnabled: enabled));
  }

  Future<void> setCategoryEnabled(String category, bool enabled) {
    final current = state.value;
    if (current == null) return Future<void>.value();
    final updated = switch (category) {
      'personal' => current.copyWith(personalEnabled: enabled),
      'group' => current.copyWith(groupEnabled: enabled),
      'community' => current.copyWith(communityEnabled: enabled),
      'system' => current.copyWith(systemEnabled: enabled),
      _ => current,
    };
    return _update(updated);
  }

  Future<void> _update(NotificationDeliveryPreferences? updated) async {
    if (updated == null) return;
    final previous = state.asData?.value;
    state = AsyncData(updated);
    try {
      await ref
          .read(notificationDeliveryPreferencesRepositoryProvider)
          .updatePreferences(updated);
      state = AsyncData(updated);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Notification preference action failed',
        error,
        stackTrace,
      );
      state = previous == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previous);
      rethrow;
    }
  }
}
