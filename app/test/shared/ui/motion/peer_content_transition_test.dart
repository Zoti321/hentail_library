import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/motion/peer_content_transition.dart';

import '../../../support/pump_app.dart';

void main() {
  group('PeerContentTransition', () {
    testWidgets('uses PageTransitionSwitcher with overlapping peer axis', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: const Scaffold(
          body: PeerContentTransition(switchKey: 0, child: Text('peer')),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsOneWidget);
      expect(find.byType(AnimatedSize), findsOneWidget);
      expect(find.text('peer'), findsOneWidget);
    });

    testWidgets('keeps taller outgoing height during first transition frame', (
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

      expect(tester.getSize(find.byType(PageTransitionSwitcher)).height, 200);

      await tester.tap(find.text('next'));
      await tester.pump();
      // 过渡中高度取 max(离开, 进入)，避免进入项单独定高导致裁切闪白。
      expect(tester.getSize(find.byType(PageTransitionSwitcher)).height, 200);

      await tester.pumpAndSettle();
      expect(find.text('short'), findsOneWidget);
      expect(find.text('tall'), findsNothing);
      expect(tester.getSize(find.byType(PageTransitionSwitcher)).height, 80);
    });

    testWidgets('reduce motion skips PageTransitionSwitcher', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: PeerContentTransition(switchKey: 0, child: Text('peer')),
          ),
        ),
      );

      expect(find.byType(PageTransitionSwitcher), findsNothing);
      expect(find.text('peer'), findsOneWidget);
    });
  });
}
