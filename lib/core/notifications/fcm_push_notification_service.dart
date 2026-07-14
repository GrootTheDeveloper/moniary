import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../shared/utils/app_logger.dart';
import 'local_notification_service.dart';

class FcmPushNotificationService {
  FcmPushNotificationService(this._localNotifications);

  final LocalNotificationService _localNotifications;
  bool _initialized = false;

  Future<void> initialize({
    required Future<void> Function(String token) onToken,
    required Future<void> Function(Map<String, dynamic> data) onTap,
  }) async {
    if (_initialized || !AppConstants.hasFirebaseConfig) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: AppConstants.firebaseApiKey,
            appId: AppConstants.firebaseAppId,
            messagingSenderId: AppConstants.firebaseMessagingSenderId,
            projectId: AppConstants.firebaseProjectId,
            iosBundleId: AppConstants.firebaseIosBundleId,
          ),
        );
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await onToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen((value) {
        unawaited(onToken(value));
      });
      FirebaseMessaging.onMessage.listen((message) {
        unawaited(_presentForegroundMessage(message));
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        unawaited(onTap(message.data));
      });
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) await onTap(initialMessage.data);
      _initialized = true;
    } catch (error, stackTrace) {
      AppLogger.error('FCM initialization failed', error, stackTrace);
    }
  }

  Future<void> _presentForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title;
    final body = notification?.body;
    if (title == null || body == null) return;

    final data = message.data;
    final category = data['category'] as String? ?? 'system';
    await _localNotifications.showIncomingNotification(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      category: category,
      channelName: data['channel_name'] as String? ?? category,
      channelDescription:
          data['channel_description'] as String? ??
          'Moniary notification updates.',
    );
  }
}
