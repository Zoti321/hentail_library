import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';

import '../../../../support/pump_app.dart';

void main() {
  group('ListDetailDetailTransition', () {
    testWidgets('uses PageTransitionSwitcher and horizontal SharedAxis', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: const Scaffold(
          body: ListDetailDetailTransition(
            switchKey: 'a',
            child: Text('pane-a'),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsOneWidget);
      final SharedAxisTransition axis = tester.widget(
        find.byType(SharedAxisTransition),
      );
      expect(axis.transitionType, SharedAxisTransitionType.horizontal);
      expect(find.text('pane-a'), findsOneWidget);
    });

    testWidgets('switches detail child when switchKey changes', (
      WidgetTester tester,
    ) async {
      Object switchKey = 'a';
      await pumpApp(
        tester,
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
      await pumpApp(
        tester,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ListDetailDetailTransition(
              switchKey: 'a',
              child: Text('pane-a'),
            ),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsNothing);
      expect(find.text('pane-a'), findsOneWidget);
    });
  });
}
