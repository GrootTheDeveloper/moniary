import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/friends/domain/friend_qr_payload.dart';

void main() {
  test('extracts token from a Moniary friend invite QR payload', () {
    expect(
      FriendQrPayload.inviteToken('moniary://friends/invite/token-123'),
      'token-123',
    );
  });

  test('rejects unrelated and malformed QR payloads', () {
    expect(FriendQrPayload.inviteToken('https://example.com'), isNull);
    expect(FriendQrPayload.inviteToken('not a uri'), isNull);
    expect(
      FriendQrPayload.inviteToken('moniary://groups/invite/token-123'),
      isNull,
    );
  });
}
