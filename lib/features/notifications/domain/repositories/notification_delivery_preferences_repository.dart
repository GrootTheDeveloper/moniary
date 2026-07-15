import '../entities/notification_delivery_preferences.dart';

abstract class NotificationDeliveryPreferencesRepository {
  Future<NotificationDeliveryPreferences> getPreferences();

  Future<void> updatePreferences(NotificationDeliveryPreferences preferences);
}
