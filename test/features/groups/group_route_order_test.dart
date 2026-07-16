import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('static create group route precedes the dynamic group route', () {
    final routerSource = File('lib/app/app_router.dart').readAsStringSync();
    final createRoute = routerSource.indexOf(
      'path: CreateGroupScreen.routePath',
    );
    final dynamicRoute = routerSource.indexOf(
      'path: GroupRoutePaths.groupPattern',
    );

    expect(createRoute, greaterThanOrEqualTo(0));
    expect(dynamicRoute, greaterThan(createRoute));
  });
}
