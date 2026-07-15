import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/notifications/fcm_push_notification_service.dart';
import 'package:moniary/core/notifications/local_notification_service.dart';

class _FakePushMessagingGateway implements PushMessagingGateway {
  final tokenRefreshController = StreamController<String>.broadcast();
  final foregroundController = StreamController<RemoteMessage>.broadcast();
  final openedController = StreamController<RemoteMessage>.broadcast();

  bool permissionGranted = true;
  String? token = 'fcm-token';
  String? apnsToken = 'apns-token';
  RemoteMessage? initialMessage;
  int deleteTokenCount = 0;
  int permissionRequestCount = 0;

  @override
  Stream<String> get tokenRefreshes => tokenRefreshController.stream;

  @override
  Stream<RemoteMessage> get foregroundMessages => foregroundController.stream;

  @override
  Stream<RemoteMessage> get openedMessages => openedController.stream;

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount++;
    return permissionGranted;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<String?> getApnsToken() async => apnsToken;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<void> deleteToken() async {
    deleteTokenCount++;
  }

  Future<void> dispose() async {
    await tokenRefreshController.close();
    await foregroundController.close();
    await openedController.close();
  }
}

void main() {
  late _FakePushMessagingGateway gateway;
  late FcmPushNotificationService service;

  setUp(() {
    gateway = _FakePushMessagingGateway();
    service = FcmPushNotificationService(
      LocalNotificationService.instance,
      messaging: gateway,
      initializeFirebase: () async {},
      firebaseConfigured: true,
      supportedPlatform: true,
      isIos: true,
    );
  });

  tearDown(() async {
    service.dispose();
    await gateway.dispose();
  });

  test('Firebase options select the platform-specific client app', () {
    final iosOptions = firebaseOptionsForPlatform(
      TargetPlatform.iOS,
      iosApiKey: 'ios-api-key',
      iosAppId: 'ios-app-id',
      iosBundleId: 'com.moniary.moniary',
      androidApiKey: 'android-api-key',
      androidAppId: 'android-app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
    );
    final androidOptions = firebaseOptionsForPlatform(
      TargetPlatform.android,
      iosApiKey: 'ios-api-key',
      iosAppId: 'ios-app-id',
      iosBundleId: 'com.moniary.moniary',
      androidApiKey: 'android-api-key',
      androidAppId: 'android-app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
    );

    expect(iosOptions.apiKey, 'ios-api-key');
    expect(iosOptions.appId, 'ios-app-id');
    expect(iosOptions.iosBundleId, 'com.moniary.moniary');
    expect(androidOptions.apiKey, 'android-api-key');
    expect(androidOptions.appId, 'android-app-id');
    expect(androidOptions.iosBundleId, isNull);
  });

  test('Firebase options reject incomplete platform configuration', () {
    expect(
      () => firebaseOptionsForPlatform(
        TargetPlatform.android,
        iosApiKey: 'ios-api-key',
        iosAppId: 'ios-app-id',
        iosBundleId: 'com.moniary.moniary',
        androidApiKey: '',
        androidAppId: 'android-app-id',
        messagingSenderId: 'sender-id',
        projectId: 'project-id',
      ),
      throwsStateError,
    );
  });

  test('iOS token registration waits until APNs token is available', () async {
    gateway.apnsToken = null;
    final registeredTokens = <String>[];

    await service.initialize(
      onToken: (token) async => registeredTokens.add(token),
      onTap: (_) async {},
    );

    expect(registeredTokens, isEmpty);

    gateway.apnsToken = 'ready-apns-token';
    await service.initialize(
      onToken: (token) async => registeredTokens.add(token),
      onTap: (_) async {},
    );

    expect(registeredTokens, ['fcm-token']);
  });

  test('sign-out unregisters and deletes the current FCM token', () async {
    final registeredTokens = <String>[];
    final unregisteredTokens = <String>[];
    await service.initialize(
      onToken: (token) async => registeredTokens.add(token),
      onTap: (_) async {},
    );

    await service.unregisterCurrentToken(
      onToken: (token) async => unregisteredTokens.add(token),
    );

    expect(registeredTokens, ['fcm-token']);
    expect(unregisteredTokens, ['fcm-token']);
    expect(gateway.deleteTokenCount, 1);

    gateway.tokenRefreshController.add('refreshed-after-sign-out');
    await Future<void>.delayed(Duration.zero);
    expect(registeredTokens, ['fcm-token']);
  });

  test('denied notification permission never registers a device', () async {
    gateway.permissionGranted = false;
    final registeredTokens = <String>[];

    await service.initialize(
      onToken: (token) async => registeredTokens.add(token),
      onTap: (_) async {},
    );

    expect(registeredTokens, isEmpty);
  });

  test(
    'concurrent initialization requests permission and token once',
    () async {
      final registeredTokens = <String>[];

      await Future.wait([
        service.initialize(
          onToken: (token) async => registeredTokens.add(token),
          onTap: (_) async {},
        ),
        service.initialize(
          onToken: (token) async => registeredTokens.add(token),
          onTap: (_) async {},
        ),
      ]);

      expect(gateway.permissionRequestCount, 1);
      expect(registeredTokens, ['fcm-token']);
    },
  );
}
