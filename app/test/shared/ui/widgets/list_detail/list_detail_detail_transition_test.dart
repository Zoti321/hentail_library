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

    testWidgets('keeps short incoming pane top-aligned during tall→short', (
      WidgetTester tester,
    ) async {
      Object switchKey = 'tall';
      await pumpApp(
        tester,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextButton(
                    onPressed: () => setState(() => switchKey = 'short'),
                    child: const Text('to-short'),
                  ),
                  ListDetailDetailTransition(
                    switchKey: switchKey,
                    reverse: true,
                    child: switchKey == 'tall'
                        ? const SizedBox(
                            key: Key('tall-pane'),
                            height: 240,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Text('tall'),
                            ),
                          )
                        : const SizedBox(
                            key: Key('short-pane'),
                            height: 80,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Text('short'),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final double tallTop = tester.getTopLeft(find.byKey(const Key('tall-pane'))).dy;

      await tester.tap(find.text('to-short'));
      await tester.pump();

      expect(find.byKey(const Key('short-pane')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('short-pane'))).dy,
        tallTop,
      );

      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('short-pane'))).dy,
        tallTop,
      );
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
