import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/utils/app_logger.dart';
import '../constants/app_constants.dart';

abstract interface class LocalNotificationGateway {
  void setNotificationTapHandler(
    Future<void> Function(String? payload)? handler,
  );

  Future<void> showIncomingNotification({
    required int id,
    required String title,
    required String body,
    required String category,
    required String channelName,
    required String channelDescription,
    String? payload,
  });
}

/// Wraps [FlutterLocalNotificationsPlugin] to schedule on-device reminders.
///
/// Everything here is delivered locally by the OS; no data leaves the device.
class LocalNotificationService implements LocalNotificationGateway {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const _channelId = 'moniary_reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription = 'Daily reminder to log your spending.';
  static const _personalChannelId = 'moniary_personal';
  static const _groupChannelId = 'moniary_group';
  static const _communityChannelId = 'moniary_community';
  static const _systemChannelId = 'moniary_system';

  /// Stable id so re-scheduling replaces the previous daily reminder.
  static const dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void> Function(String? payload)? _notificationTapHandler;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(AppConstants.defaultTimezone));
    } catch (error, stackTrace) {
      // Fall back to the default location (UTC) if the zone is unavailable.
      AppLogger.warning('Falling back to UTC for reminders: $error');
      AppLogger.error('Timezone lookup failed', error, stackTrace);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        unawaited(_dispatchNotificationTap(response.payload));
      },
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _personalChannelId,
          'Personal / Cá nhân',
          description: 'Personal Moniary notifications.',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _groupChannelId,
          'Group',
          description: 'Moniary group notifications.',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _communityChannelId,
          'Community / Cộng đồng',
          description: 'Moniary community notifications.',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _systemChannelId,
          'System / Hệ thống',
          description: 'Moniary system notifications.',
          importance: Importance.high,
        ),
      );
    }
    _initialized = true;
  }

  @override
  void setNotificationTapHandler(
    Future<void> Function(String? payload)? handler,
  ) {
    _notificationTapHandler = handler;
  }

  /// Requests OS permission to post notifications. Returns whether it was
  /// granted. On platforms without an explicit prompt this resolves to `true`.
  Future<bool> requestPermission() async {
    await init();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final darwin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (darwin != null) {
      final granted = await darwin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Schedules a reminder that repeats every day at [hour]:[minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      dailyReminderId,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(dailyReminderId);
  }

  /// Presents a safe foreground notification. The caller supplies already
  /// localized, privacy-safe copy; no personal names or amounts should be
  /// passed here because this can appear on the lock screen.
  @override
  Future<void> showIncomingNotification({
    required int id,
    required String title,
    required String body,
    required String category,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) async {
    await init();
    final channelId = switch (category) {
      'personal' => _personalChannelId,
      'group' => _groupChannelId,
      'community' => _communityChannelId,
      _ => _systemChannelId,
    };
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: channelId),
      ),
      payload: payload,
    );
  }

  Future<void> _dispatchNotificationTap(String? payload) async {
    final handler = _notificationTapHandler;
    if (handler == null) return;
    try {
      await handler(payload);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Local notification tap handler failed',
        error,
        stackTrace,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
