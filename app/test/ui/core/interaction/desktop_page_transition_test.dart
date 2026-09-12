import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/interaction/desktop_page_transition.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  @override
  ValueKey<String> get pageKey => const ValueKey<String>('shell-page');

  @override
  String? get name => 'shell';
}

void main() {
  tearDown(debugResetPendingShellFadeThrough);

  group('shell nav pending fade-through', () {
    test('library shell page stays NoTransition without a pending request', () {
      final Page<void> page = buildShellNavPage(
        state: _FakeGoRouterState(),
        child: const SizedBox(),
        allowPendingFadeThrough: true,
      );

      expect(page, isA<NoTransitionPage<void>>());
    });

    test(
      'one-shot request makes the next allowPendingFadeThrough page fade-through',
      () {
        requestShellFadeThroughOnce();

        final Page<void> animated = buildShellNavPage(
          state: _FakeGoRouterState(),
          child: const SizedBox(),
          allowPendingFadeThrough: true,
        );
        expect(animated, isA<CustomTransitionPage<void>>());
        final CustomTransitionPage<void> custom =
            animated as CustomTransitionPage<void>;
        expect(custom.transitionDuration, kDesktopPageTransitionDuration);
        expect(
          custom.reverseTransitionDuration,
          kDesktopPageTransitionDuration,
        );

        final Page<void> next = buildShellNavPage(
          state: _FakeGoRouterState(),
          child: const SizedBox(),
          allowPendingFadeThrough: true,
        );
        expect(next, isA<NoTransitionPage<void>>());
      },
    );

    test(
      'pending request is ignored when allowPendingFadeThrough is false',
      () {
        requestShellFadeThroughOnce();

        final Page<void> page = buildShellNavPage(
          state: _FakeGoRouterState(),
          child: const SizedBox(),
        );
        expect(page, isA<NoTransitionPage<void>>());
        expect(debugPendingShellFadeThrough, isTrue);
      },
    );
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

    test('covered route fades out during the first half of secondary', () {
      expect(desktopFadeThroughCoveredOpacity(0.0), 1.0);
      expect(desktopFadeThroughCoveredOpacity(0.5), 0.0);
      expect(desktopFadeThroughCoveredOpacity(1.0), 0.0);
    });

    test('uncovered route fades in during the second half of secondary', () {
      expect(desktopFadeThroughUncoveredOpacity(0.0), 0.0);
      expect(desktopFadeThroughUncoveredOpacity(0.5), 0.0);
      expect(desktopFadeThroughUncoveredOpacity(1.0), 1.0);
    });

    testWidgets(
      'secondary animation uses covered vs uncovered based on pop flag',
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

        secondary.value = 0.25;
        expect(
          resolveDesktopFadeThroughOpacity(
            animation: primary,
            secondaryAnimation: secondary,
            revealingFromPop: false,
          ),
          desktopFadeThroughCoveredOpacity(0.25),
        );

        secondary.value = 0.75;
        expect(
          resolveDesktopFadeThroughOpacity(
            animation: primary,
            secondaryAnimation: secondary,
            revealingFromPop: true,
          ),
          desktopFadeThroughUncoveredOpacity(0.75),
        );
      },
    );
  });
}
