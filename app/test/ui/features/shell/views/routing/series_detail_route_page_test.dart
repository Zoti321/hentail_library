import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/interaction/desktop_page_transition.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  @override
  ValueKey<String> get pageKey => const ValueKey<String>('test-page');

  @override
  String? get name => 'test';
}

void main() {
  test('buildDesktopFadeThroughPage uses 280ms fade-through transition', () {
    final Page<void> page = buildDesktopFadeThroughPage(
      state: _FakeGoRouterState(),
      child: const SizedBox(),
    );

    expect(page, isA<CustomTransitionPage<void>>());
    final CustomTransitionPage<void> custom =
        page as CustomTransitionPage<void>;
    expect(custom.transitionDuration, kDesktopPageTransitionDuration);
    expect(custom.reverseTransitionDuration, kDesktopPageTransitionDuration);
  });
}
