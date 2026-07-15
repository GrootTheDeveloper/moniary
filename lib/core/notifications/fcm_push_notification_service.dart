import 'dart:async';
import 'dart:convert';

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
  String? _registeredToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

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
          options: FirebaseOptions(
            apiKey: AppConstants.firebaseApiKey,
            appId: AppConstants.firebaseAppId,
            messagingSenderId: AppConstants.firebaseMessagingSenderId,
            projectId: AppConstants.firebaseProjectId,
            iosBundleId: AppConstants.firebaseIosBundleId,
          ),
        );
      }

      final messaging = FirebaseMessaging.instance;
      _localNotifications.setNotificationTapHandler((payload) async {
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            await onTap(Map<String, dynamic>.from(decoded));
          }
        } catch (error, stackTrace) {
          AppLogger.error(
            'Foreground notification payload is invalid',
            error,
            stackTrace,
          );
        }
      });
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(onToken, token);
      }
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((value) {
            unawaited(_registerToken(onToken, value));
          });
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        unawaited(_presentForegroundMessage(message));
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        unawaited(onTap(message.data));
      });
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) await onTap(initialMessage.data);
      _initialized = true;
    } catch (error, stackTrace) {
      AppLogger.error('FCM initialization failed', error, stackTrace);
    }
  }

  Future<void> unregisterCurrentDevice(
    Future<void> Function(String token) onToken,
  ) async {
    final token = _registeredToken;
    if (token != null) {
      try {
        await onToken(token);
      } catch (error, stackTrace) {
        AppLogger.error('FCM device unregister failed', error, stackTrace);
      }
    }
    await reset();
  }

  Future<void> reset() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _registeredToken = null;
    _initialized = false;
  }

  Future<void> _registerToken(
    Future<void> Function(String token) onToken,
    String token,
  ) async {
    try {
      await onToken(token);
      _registeredToken = token;
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
      payload: jsonEncode(data),
    );
  }
}
