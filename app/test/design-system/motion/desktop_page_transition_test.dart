import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/design-system/design_system.dart';

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

  group('official fade-through opacity sequences', () {
    test('enter stays zero until 6/20 then rises', () {
      expect(desktopFadeThroughEnterOpacity(0.0), 0.0);
      expect(desktopFadeThroughEnterOpacity(kFadeThroughIncomingStart), 0.0);
      expect(desktopFadeThroughEnterOpacity(1.0), 1.0);
      expect(
        desktopFadeThroughEnterOpacity(kFadeThroughIncomingStart + 0.01),
        greaterThan(0.0),
      );
    });

    test('exit reaches zero by 6/20 and stays zero', () {
      expect(desktopFadeThroughExitOpacity(0.0), 1.0);
      expect(desktopFadeThroughExitOpacity(kFadeThroughOutgoingEnd), 0.0);
      expect(desktopFadeThroughExitOpacity(1.0), 0.0);
    });

    test('enter and exit never both opaque at the same progress', () {
      for (int i = 0; i <= 20; i++) {
        final double t = i / 20;
        final double enter = desktopFadeThroughEnterOpacity(t);
        final double exit = desktopFadeThroughExitOpacity(t);
        expect(
          enter * exit,
          0.0,
          reason: 'at t=$t enter=$enter exit=$exit should not overlap',
        );
      }
    });
  });

  group('desktopFadeThroughTransitionWrapper', () {
    testWidgets('uses FadeThroughTransition with stopped secondary', (
      WidgetTester tester,
    ) async {
      final AnimationController primary = AnimationController(
        vsync: tester,
        value: 1,
      );
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return desktopFadeThroughTransitionWrapper(
                context: context,
                animation: primary,
                secondaryAnimation: const AlwaysStoppedAnimation<double>(0.5),
                child: const Text('content'),
              );
            },
          ),
        ),
      );

      final FadeThroughTransition fade = tester.widget(
        find.byType(FadeThroughTransition),
      );
      expect(fade.secondaryAnimation.value, 0.0);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
