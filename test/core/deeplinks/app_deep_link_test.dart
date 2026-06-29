import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/deeplinks/app_deep_link.dart';

void main() {
  test('parse moniary friend invite link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary://friends/invite/token-123'),
    );

    expect(deepLink, isA<FriendInviteDeepLink>());
    expect(
      (deepLink as FriendInviteDeepLink).routeLocation,
      '/friends/invite/token-123',
    );
  });

  test('parse slash-style moniary friend invite link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary:///friends/invite/token-123'),
    );

    expect(deepLink, isA<FriendInviteDeepLink>());
    expect(
      (deepLink as FriendInviteDeepLink).routeLocation,
      '/friends/invite/token-123',
    );
  });

  test('ignore unrelated links', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary://groups/other/abc'),
    );

    expect(deepLink, isNull);
  });

  test('parse moniary group invite link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary://groups/invite/group-token'),
    );

    expect(deepLink, isA<GroupInviteDeepLink>());
    expect(
      (deepLink as GroupInviteDeepLink).routeLocation,
      '/groups/invite/accept/group-token',
    );
  });

  test('parse slash-style moniary group invite link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary:///groups/invite/group-token'),
    );

    expect(deepLink, isA<GroupInviteDeepLink>());
    expect(
      (deepLink as GroupInviteDeepLink).routeLocation,
      '/groups/invite/accept/group-token',
    );
  });
}
