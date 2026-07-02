import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/deeplinks/pending_deep_link_controller.dart';

void main() {
  test('consume returns pending route once and clears it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(pendingDeepLinkProvider.notifier)
        .set('/friends/invite/token-1');

    expect(
      container.read(pendingDeepLinkProvider.notifier).consume(),
      '/friends/invite/token-1',
    );
    expect(container.read(pendingDeepLinkProvider), isNull);
    expect(container.read(pendingDeepLinkProvider.notifier).consume(), isNull);
  });
}
