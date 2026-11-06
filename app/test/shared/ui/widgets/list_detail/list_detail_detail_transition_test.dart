import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';

void main() {
  group('listDetailFadeThrough opacity', () {
    test('enter stays zero for the first half then rises', () {
      expect(listDetailFadeThroughEnterOpacity(0.0), 0.0);
      expect(listDetailFadeThroughEnterOpacity(0.5), 0.0);
      expect(listDetailFadeThroughEnterOpacity(1.0), 1.0);
    });

    test('outgoing on reverse anim fades only while value > 0.5', () {
      expect(listDetailFadeThroughOutgoingOpacity(1.0), 1.0);
      expect(listDetailFadeThroughOutgoingOpacity(0.5), 0.0);
      expect(listDetailFadeThroughOutgoingOpacity(0.0), 0.0);
    });

    test('enter and outgoing never both opaque at the same progress', () {
      for (int i = 0; i <= 20; i++) {
        final double t = i / 20;
        final double enter = listDetailFadeThroughEnterOpacity(t);
        // Outgoing ReverseAnimation value at forward progress t is 1 - t.
        final double outgoing = listDetailFadeThroughOutgoingOpacity(1.0 - t);
        expect(
          enter * outgoing,
          0.0,
          reason: 'at t=$t enter=$enter outgoing=$outgoing should not overlap',
        );
      }
    });

    test('spring overshoot beyond 0..1 does not throw and clamps opacity', () {
      expect(listDetailFadeThroughEnterOpacity(1.05), 1.0);
      expect(listDetailFadeThroughEnterOpacity(-0.05), 0.0);
      expect(listDetailFadeThroughOutgoingOpacity(1.05), 1.0);
      expect(listDetailFadeThroughOutgoingOpacity(-0.05), 0.0);
    });
  });

  group('ListDetailDetailTransition', () {
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
  });
}
