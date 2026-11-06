import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/shared_axis_route.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  @override
  ValueKey<String> get pageKey => const ValueKey<String>('reader-page');

  @override
  String? get name => '阅读';
}

void main() {
  group('buildSharedAxisPage', () {
    test('returns horizontal SharedAxis page for reader-style push', () {
      final CustomTransitionPage<void> page = buildSharedAxisPage(
        state: _FakeGoRouterState(),
        child: const SizedBox(),
      );

      expect(page.transitionDuration, kSharedAxisRouteDuration);
      expect(page.reverseTransitionDuration, kSharedAxisRouteDuration);
    });
  });

  group('sharedAxisTransitionWrapper', () {
    testWidgets('uses horizontal SharedAxisTransition by default', (
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
              return sharedAxisTransitionWrapper(
                context: context,
                animation: primary,
                secondaryAnimation: const AlwaysStoppedAnimation<double>(0),
                fillColor: Colors.black,
                child: const Text('reader'),
              );
            },
          ),
        ),
      );

      final SharedAxisTransition axis = tester.widget(
        find.byType(SharedAxisTransition),
      );
      expect(axis.transitionType, SharedAxisTransitionType.horizontal);
      expect(find.text('reader'), findsOneWidget);
    });

    testWidgets('mirrors horizontal axis when reverse is true', (
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
              return sharedAxisTransitionWrapper(
                context: context,
                animation: primary,
                secondaryAnimation: const AlwaysStoppedAnimation<double>(0),
                fillColor: Colors.black,
                reverse: true,
                child: const Text('reader'),
              );
            },
          ),
        ),
      );

      expect(find.byType(SharedAxisTransition), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
      expect(find.text('reader'), findsOneWidget);
    });

    testWidgets('skips SharedAxis when reduce motion is on', (
      WidgetTester tester,
    ) async {
      final AnimationController primary = AnimationController(
        vsync: tester,
        value: 1,
      );
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: Builder(
            builder: (BuildContext context) {
              return sharedAxisTransitionWrapper(
                context: context,
                animation: primary,
                secondaryAnimation: const AlwaysStoppedAnimation<double>(0),
                fillColor: Colors.black,
                child: const Text('reader'),
              );
            },
          ),
        ),
      );

      expect(find.byType(SharedAxisTransition), findsNothing);
      expect(find.text('reader'), findsOneWidget);
    });
  });
}
