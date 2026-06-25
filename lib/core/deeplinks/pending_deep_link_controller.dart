import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingDeepLinkProvider =
    NotifierProvider<PendingDeepLinkController, String?>(
      PendingDeepLinkController.new,
    );

class PendingDeepLinkController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String routeLocation) {
    state = routeLocation;
  }

  String? consume() {
    final routeLocation = state;
    state = null;
    return routeLocation;
  }
}
