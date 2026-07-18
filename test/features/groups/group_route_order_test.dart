import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('static group routes precede the dynamic group route', () {
    final routerSource = File('lib/app/app_router.dart').readAsStringSync();
    final createRoute = routerSource.indexOf(
      'path: CreateGroupScreen.routePath',
    );
    final sharedInviteRoute = routerSource.indexOf(
      'path: GroupInviteAcceptScreen.routePath',
    );
    final directInvitesRoute = routerSource.indexOf(
      'path: GroupInvitationsScreen.routePath',
    );
    final dynamicRoute = routerSource.indexOf(
      'path: GroupRoutePaths.groupPattern',
    );

    expect(createRoute, greaterThanOrEqualTo(0));
    expect(sharedInviteRoute, greaterThanOrEqualTo(0));
    expect(directInvitesRoute, greaterThanOrEqualTo(0));
    expect(dynamicRoute, greaterThan(createRoute));
    expect(dynamicRoute, greaterThan(sharedInviteRoute));
    expect(dynamicRoute, greaterThan(directInvitesRoute));
  });
}
