import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  @override
  ValueKey<String> get pageKey => const ValueKey<String>('shell-page');

  @override
  String? get name => 'shell';
}

void main() {
  group('buildShellNavPage', () {
    test('returns desktop fade-through for shell top-level nav', () {
      final Page<void> page = buildShellNavPage(
        state: _FakeGoRouterState(),
        child: const SizedBox(),
      );

      expect(page, isA<CustomTransitionPage<void>>());
      final CustomTransitionPage<void> custom =
          page as CustomTransitionPage<void>;
      expect(custom.transitionDuration, kDesktopPageTransitionDuration);
      expect(custom.reverseTransitionDuration, kDesktopPageTransitionDuration);
    });
  });

  group('desktop fade-through opacity curves', () {
    test('enter is zero for the first half then eases in', () {
      expect(desktopFadeThroughEnterOpacity(0.0), 0.0);
      expect(desktopFadeThroughEnterOpacity(0.5), 0.0);
      expect(desktopFadeThroughEnterOpacity(1.0), 1.0);
    });

    test('exit stays visible for the first half then eases out', () {
      expect(desktopFadeThroughExitOpacity(1.0), 1.0);
      expect(desktopFadeThroughExitOpacity(0.5), 1.0);
      expect(desktopFadeThroughExitOpacity(0.0), 0.0);
    });

    testWidgets(
      'covered route stays opaque while secondary runs (no white flash under detail)',
      (WidgetTester tester) async {
        final AnimationController primary = AnimationController(
          vsync: tester,
          value: 1,
        );
        final AnimationController secondary = AnimationController(
          vsync: tester,
          duration: kDesktopPageTransitionDuration,
        );
        addTearDown(primary.dispose);
        addTearDown(secondary.dispose);

        for (final double t in <double>[0.25, 0.5, 0.75, 1.0]) {
          secondary.value = t;
          expect(
            resolveDesktopFadeThroughOpacity(
              animation: primary,
              secondaryAnimation: secondary,
            ),
            1.0,
          );
        }
      },
    );
  });
}
