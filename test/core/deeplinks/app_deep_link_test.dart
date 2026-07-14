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

  test('parse moniary group invite link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary://groups/invite/abc'),
    );

    expect(deepLink, isA<GroupInviteDeepLink>());
    expect(
      (deepLink as GroupInviteDeepLink).routeLocation,
      '/groups/invite/abc',
    );
  });

  test('parse https friend invite app link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('https://go.vuivethoima.id.vn/friends/invite/token-123'),
    );

    expect(deepLink, isA<FriendInviteDeepLink>());
    expect(
      (deepLink as FriendInviteDeepLink).routeLocation,
      '/friends/invite/token-123',
    );
  });

  test('parse https group invite app link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('https://go.vuivethoima.id.vn/groups/invite/abc'),
    );

    expect(deepLink, isA<GroupInviteDeepLink>());
    expect(
      (deepLink as GroupInviteDeepLink).routeLocation,
      '/groups/invite/abc',
    );
  });

  test('ignore invite paths from untrusted https hosts', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('https://example.com/groups/invite/abc'),
    );

    expect(deepLink, isNull);
  });

  test('ignore unrelated links', () {
    final deepLink = AppDeepLink.parse(Uri.parse('moniary://unknown/path/abc'));

    expect(deepLink, isNull);
  });

  test('parse slash-style moniary group invite link', () {
    final deepLink = AppDeepLink.parse(
      Uri.parse('moniary:///groups/invite/group-token'),
    );

    expect(deepLink, isA<GroupInviteDeepLink>());
    expect(
      (deepLink as GroupInviteDeepLink).routeLocation,
      '/groups/invite/group-token',
    );
  });
}
