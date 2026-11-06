import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';

void main() {
  group('ListDetailDetailTransition', () {
    testWidgets('uses PageTransitionSwitcher and FadeThroughTransition', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListDetailDetailTransition(
              switchKey: 'a',
              child: Text('pane-a'),
            ),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsOneWidget);
      expect(find.byType(FadeThroughTransition), findsWidgets);
      expect(find.text('pane-a'), findsOneWidget);
    });

    testWidgets('switches detail child when switchKey changes', (
      WidgetTester tester,
    ) async {
      Object switchKey = 'a';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: <Widget>[
                    TextButton(
                      onPressed: () => setState(() => switchKey = 'b'),
                      child: const Text('switch'),
                    ),
                    Expanded(
                      child: ListDetailDetailTransition(
                        switchKey: switchKey,
                        child: Text('pane-$switchKey'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('pane-a'), findsOneWidget);

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();
      expect(find.text('pane-b'), findsOneWidget);
      expect(find.text('pane-a'), findsNothing);
    });

    testWidgets('reduce motion skips PageTransitionSwitcher', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ListDetailDetailTransition(
                switchKey: 'a',
                child: Text('pane-a'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsNothing);
      expect(find.text('pane-a'), findsOneWidget);
    });
  });
}
