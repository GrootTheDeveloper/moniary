import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../shared/utils/app_logger.dart';
import 'local_notification_service.dart';

enum PushPermissionStatus { unavailable, notDetermined, denied, authorized }

@visibleForTesting
FirebaseOptions firebaseOptionsForPlatform(
  TargetPlatform platform, {
  String iosApiKey = AppConstants.firebaseIosApiKey,
  String iosAppId = AppConstants.firebaseIosAppId,
  String iosBundleId = AppConstants.firebaseIosBundleId,
  String androidApiKey = AppConstants.firebaseAndroidApiKey,
  String androidAppId = AppConstants.firebaseAndroidAppId,
  String messagingSenderId = AppConstants.firebaseMessagingSenderId,
  String projectId = AppConstants.firebaseProjectId,
}) {
  final isIos = platform == TargetPlatform.iOS;
  final isAndroid = platform == TargetPlatform.android;
  if (!isIos && !isAndroid) {
    throw UnsupportedError('Firebase push is supported only on iOS/Android.');
  }

  final apiKey = isIos ? iosApiKey : androidApiKey;
  final appId = isIos ? iosAppId : androidAppId;
  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty ||
      (isIos && iosBundleId.isEmpty)) {
    throw StateError('Firebase configuration is incomplete for $platform.');
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    iosBundleId: isIos ? iosBundleId : null,
  );
}

abstract interface class PushMessagingGateway {
  Stream<String> get tokenRefreshes;
  Stream<RemoteMessage> get foregroundMessages;
  Stream<RemoteMessage> get openedMessages;

  Future<bool> requestPermission();
  Future<PushPermissionStatus> getPermissionStatus();
  Future<String?> getToken();
  Future<String?> getApnsToken();
  Future<RemoteMessage?> getInitialMessage();
  Future<void> deleteToken();
}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<PushPermissionStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermissionStatus.authorized,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
    };
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<String?> getApnsToken() => _messaging.getAPNSToken();

  @override
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  @override
  Future<void> deleteToken() => _messaging.deleteToken();
}

class FcmPushNotificationService {
  FcmPushNotificationService(
    this._localNotifications, {
    PushMessagingGateway? messaging,
    Future<void> Function()? initializeFirebase,
    bool? firebaseConfigured,
    bool? supportedPlatform,
    bool? isIos,
  }) : _messaging = messaging,
       _initializeFirebaseOverride = initializeFirebase,
       _firebaseConfigured =
           firebaseConfigured ?? AppConstants.hasFirebaseConfig,
       _supportedPlatform = supportedPlatform ?? _defaultSupportedPlatform,
       _isIos =
           isIos ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  final LocalNotificationGateway _localNotifications;
  final Future<void> Function()? _initializeFirebaseOverride;
  final bool _firebaseConfigured;
  final bool _supportedPlatform;
  final bool _isIos;

  PushMessagingGateway? _messaging;
  Future<void>? _initializing;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Timer? _registrationRetry;
  Future<bool>? _permissionRequest;
  Future<void>? _registration;
  Future<void> Function(String token)? _onToken;
  Future<void> Function(Map<String, dynamic> data)? _onTap;
  String? _lastRegisteredToken;
  bool _firebaseReady = false;
  bool _listenersReady = false;
  bool _permissionGranted = false;
  bool _signedOut = false;

  static bool get _defaultSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isAvailable => _firebaseConfigured && _supportedPlatform;

  Future<void> initialize({
    required Future<void> Function(String token) onToken,
    required Future<void> Function(Map<String, dynamic> data) onTap,
    bool requestPermission = true,
    bool registerDevice = true,
  }) async {
    if (!_firebaseConfigured || !_supportedPlatform) return;

    _onToken = onToken;
    _onTap = onTap;
    _signedOut = false;
    _localNotifications.setNotificationTapHandler(_handleLocalNotificationTap);

    try {
      await _ensureFirebaseReady();
      final messaging = _messaging;
      if (!_firebaseReady || messaging == null) return;

      _permissionGranted = requestPermission
          ? await _ensurePermission(messaging)
          : await messaging.getPermissionStatus() ==
                PushPermissionStatus.authorized;
      if (!_permissionGranted) {
        AppLogger.info('Push notification permission is not granted.');
        return;
      }

      if (registerDevice) await _ensureCurrentTokenRegistered();
    } catch (error, stackTrace) {
      AppLogger.error('FCM initialization failed', error, stackTrace);
    }
  }

  Future<PushPermissionStatus> permissionStatus() async {
    if (!isAvailable) return PushPermissionStatus.unavailable;
    try {
      await _ensureFirebaseReady();
      final messaging = _messaging;
      if (messaging == null) return PushPermissionStatus.unavailable;
      return messaging.getPermissionStatus();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to read push permission status',
        error,
        stackTrace,
      );
      return PushPermissionStatus.unavailable;
    }
  }

  Future<bool> requestPermissionAndRegister() async {
    if (!isAvailable) return false;
    _signedOut = false;
    try {
      await _ensureFirebaseReady();
      final messaging = _messaging;
      if (messaging == null) return false;
      _permissionGranted = await _ensurePermission(messaging);
      if (!_permissionGranted) return false;
      await _ensureCurrentTokenRegistered();
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('Push permission request failed', error, stackTrace);
      return false;
    }
  }

  Future<void> unregisterCurrentToken({
    required Future<void> Function(String token) onToken,
  }) async {
    if (!_firebaseConfigured || !_supportedPlatform) return;

    _signedOut = true;
    _registrationRetry?.cancel();
    _registrationRetry = null;

    final initializing = _initializing;
    if (initializing != null) {
      try {
        await initializing;
      } catch (_) {
        // Initialization already logs its failure. There cannot be a token to
        // unregister if Firebase never became ready.
      }
    }

    final messaging = _messaging;
    if (!_firebaseReady || messaging == null) return;

    final tokens = <String>{};
    final registeredToken = _lastRegisteredToken?.trim();
    if (registeredToken?.isNotEmpty == true) tokens.add(registeredToken!);
    try {
      final currentToken = (await messaging.getToken())?.trim();
      if (currentToken?.isNotEmpty == true) tokens.add(currentToken!);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to read FCM token during sign-out',
        error,
        stackTrace,
      );
    }

    for (final token in tokens) {
      try {
        await onToken(token);
      } catch (error, stackTrace) {
        // Deleting the local FCM token below makes it unusable even when the
        // Supabase unregister call is temporarily unavailable.
        AppLogger.error('FCM token unregister failed', error, stackTrace);
      }
    }

    try {
      await messaging.deleteToken();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to delete local FCM token', error, stackTrace);
    }
    _lastRegisteredToken = null;
  }

  Future<void> _ensureFirebaseReady() async {
    if (_firebaseReady) return;
    final existing = _initializing;
    if (existing != null) return existing;

    final future = _initializeFirebase();
    _initializing = future;
    try {
      await future;
    } finally {
      if (identical(_initializing, future)) _initializing = null;
    }
  }

  Future<void> _initializeFirebase() async {
    if (_initializeFirebaseOverride != null) {
      await _initializeFirebaseOverride();
    } else if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: firebaseOptionsForPlatform(defaultTargetPlatform),
      );
    }

    _messaging ??= FirebasePushMessagingGateway(FirebaseMessaging.instance);
    final messaging = _messaging!;

    if (!_listenersReady) {
      _tokenRefreshSubscription = messaging.tokenRefreshes.listen((token) {
        if (!_signedOut) unawaited(_registerToken(token));
      });
      _foregroundSubscription = messaging.foregroundMessages.listen((message) {
        unawaited(_presentForegroundMessage(message));
      });
      _openedSubscription = messaging.openedMessages.listen((message) {
        if (!_signedOut) unawaited(_onTap?.call(message.data));
      });
      _listenersReady = true;
    }

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null && !_signedOut) {
      await _onTap?.call(initialMessage.data);
    }
    _firebaseReady = true;
  }

  Future<bool> _ensurePermission(PushMessagingGateway messaging) async {
    if (_permissionGranted) return true;
    final existing = _permissionRequest;
    if (existing != null) return existing;

    final future = messaging.requestPermission();
    _permissionRequest = future;
    try {
      return await future;
    } finally {
      if (identical(_permissionRequest, future)) _permissionRequest = null;
    }
  }

  Future<void> _ensureCurrentTokenRegistered({
    int retriesRemaining = 10,
  }) async {
    final existing = _registration;
    if (existing != null) return existing;

    final future = _registerCurrentToken(retriesRemaining: retriesRemaining);
    _registration = future;
    try {
      await future;
    } finally {
      if (identical(_registration, future)) _registration = null;
    }
  }

  Future<void> _registerCurrentToken({int retriesRemaining = 10}) async {
    if (_signedOut || !_permissionGranted) return;
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      if (_isIos) {
        final apnsToken = await messaging.getApnsToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          _scheduleRegistrationRetry(retriesRemaining);
          return;
        }
      }

      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        _scheduleRegistrationRetry(retriesRemaining);
        return;
      }
      await _registerToken(token);
    } catch (error, stackTrace) {
      AppLogger.error('FCM token lookup failed', error, stackTrace);
      _scheduleRegistrationRetry(retriesRemaining);
    }
  }

  void _scheduleRegistrationRetry(int retriesRemaining) {
    if (_signedOut || retriesRemaining <= 0) {
      if (retriesRemaining <= 0) {
        AppLogger.warning('APNs/FCM token was not ready after retrying.');
      }
      return;
    }
    _registrationRetry?.cancel();
    _registrationRetry = Timer(const Duration(seconds: 1), () {
      unawaited(
        _ensureCurrentTokenRegistered(retriesRemaining: retriesRemaining - 1),
      );
    });
  }

  Future<void> _registerToken(String token) async {
    if (_signedOut) return;
    final normalizedToken = token.trim();
    final onToken = _onToken;
    if (normalizedToken.isEmpty || onToken == null) return;
    try {
      await onToken(normalizedToken);
      _lastRegisteredToken = normalizedToken;
    } catch (error, stackTrace) {
      AppLogger.error('FCM token registration failed', error, stackTrace);
    }
  }

  Future<void> _presentForegroundMessage(RemoteMessage message) async {
    if (_signedOut) return;
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

  Future<void> _handleLocalNotificationTap(String? payload) async {
    if (_signedOut || payload == null || payload.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      await _onTap?.call(Map<String, dynamic>.from(decoded));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Foreground notification payload is invalid',
        error,
        stackTrace,
      );
    }
  }

  void dispose() {
    _registrationRetry?.cancel();
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    _localNotifications.setNotificationTapHandler(null);
  }
}
