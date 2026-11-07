import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/motion/peer_content_transition.dart';

import '../../../support/pump_app.dart';

void main() {
  group('PeerContentTransition', () {
    test('incomingEntryIndex matches PageTransitionSwitcher insert rules', () {
      expect(
        PeerContentTransition.incomingEntryIndex(1, reverse: false),
        0,
      );
      expect(
        PeerContentTransition.incomingEntryIndex(2, reverse: false),
        1,
      );
      expect(
        PeerContentTransition.incomingEntryIndex(2, reverse: true),
        0,
      );
      expect(
        PeerContentTransition.incomingEntryIndex(3, reverse: true),
        1,
      );
    });

    testWidgets('uses horizontal SharedAxis and sizes to incoming child', (
      WidgetTester tester,
    ) async {
      int key = 0;
      await pumpApp(
        tester,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  TextButton(
                    onPressed: () => setState(() => key += 1),
                    child: const Text('next'),
                  ),
                  PeerContentTransition(
                    switchKey: key,
                    child: key == 0
                        ? const SizedBox(height: 200, child: Text('tall'))
                        : const SizedBox(height: 80, child: Text('short')),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsOneWidget);
      expect(
        tester.getSize(find.byType(PageTransitionSwitcher)).height,
        200,
      );

      await tester.tap(find.text('next'));
      await tester.pump();
      // 过渡首帧起高度应由进入项（短）决定，而不是取 max(旧, 新)。
      expect(
        tester.getSize(find.byType(PageTransitionSwitcher)).height,
        80,
      );

      await tester.pumpAndSettle();
      expect(find.text('short'), findsOneWidget);
      expect(find.text('tall'), findsNothing);
    });

    testWidgets('reduce motion skips PageTransitionSwitcher', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: PeerContentTransition(
              switchKey: 0,
              child: Text('peer'),
            ),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsNothing);
      expect(find.text('peer'), findsOneWidget);
    });
  });
}
