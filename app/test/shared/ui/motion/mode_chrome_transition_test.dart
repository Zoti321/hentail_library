import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/motion/mode_chrome_transition.dart';

import '../../../support/pump_app.dart';

void main() {
  group('ModeChromeTransition', () {
    testWidgets('uses PageTransitionSwitcher and vertical SharedAxis', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: const Scaffold(
          body: ModeChromeTransition(
            switchKey: false,
            child: Text('browse'),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsOneWidget);
      final SharedAxisTransition axis = tester.widget(
        find.byType(SharedAxisTransition),
      );
      expect(axis.transitionType, SharedAxisTransitionType.vertical);
      expect(find.text('browse'), findsOneWidget);
    });

    testWidgets('switches child when switchKey changes', (
      WidgetTester tester,
    ) async {
      bool selection = false;
      await pumpApp(
        tester,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  TextButton(
                    onPressed: () => setState(() => selection = !selection),
                    child: const Text('toggle'),
                  ),
                  ModeChromeTransition(
                    switchKey: selection,
                    reverse: !selection,
                    child: Text(selection ? 'select' : 'browse'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('browse'), findsOneWidget);
      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();
      expect(find.text('select'), findsOneWidget);
      expect(find.text('browse'), findsNothing);
    });

    testWidgets('reduce motion skips PageTransitionSwitcher', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ModeChromeTransition(
              switchKey: false,
              child: Text('browse'),
            ),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsNothing);
      expect(find.text('browse'), findsOneWidget);
    });
  });
}
