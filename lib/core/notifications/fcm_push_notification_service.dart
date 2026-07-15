import 'dart:async';
import 'dart:io';

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
    if (_initialized) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        if (AppConstants.hasFirebaseConfig) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: AppConstants.firebaseApiKey,
              appId: AppConstants.firebaseAppId,
              messagingSenderId: AppConstants.firebaseMessagingSenderId,
              projectId: AppConstants.firebaseProjectId,
              iosBundleId: AppConstants.firebaseIosBundleId,
            ),
          );
        } else {
          await Firebase.initializeApp();
        }
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.warning('Push notification permission denied');
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _readFcmToken(messaging);
      if (token != null && token.isNotEmpty) {
        await _registerToken(onToken, token);
      } else {
        AppLogger.warning('FCM token was not available after permission grant');
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((value) {
        unawaited(_registerToken(onToken, value));
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

  Future<String?> _readFcmToken(FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      for (var attempt = 0; attempt < 10; attempt++) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    return messaging.getToken();
  }

  Future<void> _registerToken(
    Future<void> Function(String token) onToken,
    String token,
  ) async {
    try {
      await onToken(token);
    } catch (error, stackTrace) {
      AppLogger.error('FCM token registration failed', error, stackTrace);
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
