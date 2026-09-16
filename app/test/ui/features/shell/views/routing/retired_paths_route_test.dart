import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/shared_content_routes.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeGoRouterState extends Fake implements GoRouterState {}

void main() {
  test('retired /paths deep link redirects to Home (ADR-0014)', () async {
    final List<RouteBase> routes = buildSharedContentRoutes();
    final GoRoute pathsRoute = routes.whereType<GoRoute>().singleWhere(
      (GoRoute route) => route.path == '/paths',
    );

    expect(
      pathsRoute.builder,
      isNull,
      reason: 'Selected Paths page is retired; the route must not build a page',
    );
    expect(pathsRoute.redirect, isNotNull);
    final FutureOr<String?> target = pathsRoute.redirect!(
      _FakeBuildContext(),
      _FakeGoRouterState(),
    );
    expect(await Future<String?>.value(target), '/home');
  });
}
