import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/overlays/anchored_overlay_menu.dart';

void main() {
  group('resolveAnchoredOverlayMenuOffset', () {
    test('left-side anchor left-aligns menu (sidebar-expanded case)', () {
      // Overlay 1440 wide; content after 256 sidebar; button near content left.
      const Size overlaySize = Size(1440, 900);
      const Size menuSize = Size(200, 120);
      final RelativeRect anchor = RelativeRect.fromLTRB(
        300,
        8,
        1440 - 332,
        900 - 40,
      );

      final Offset origin = resolveAnchoredOverlayMenuOffset(
        anchor: anchor,
        overlaySize: overlaySize,
        menuSize: menuSize,
        textDirection: TextDirection.ltr,
      );

      expect(origin.dx, 300);
      expect(origin.dy, 8);
    });

    test('right-side anchor right-aligns menu', () {
      const Size overlaySize = Size(1440, 900);
      const Size menuSize = Size(200, 120);
      // Button [1300, 1332]; closer to right edge.
      final RelativeRect anchor = RelativeRect.fromLTRB(
        1300,
        8,
        1440 - 1332,
        900 - 40,
      );

      final Offset origin = resolveAnchoredOverlayMenuOffset(
        anchor: anchor,
        overlaySize: overlaySize,
        menuSize: menuSize,
        textDirection: TextDirection.ltr,
      );

      // size.width - position.right - menuWidth
      expect(origin.dx, 1440 - (1440 - 1332) - 200);
      expect(origin.dy, 8);
    });

    test('clamps when left-aligned menu would overflow the right edge', () {
      const Size overlaySize = Size(400, 900);
      const Size menuSize = Size(280, 120);
      // Closer to left (150 < 218) so left-align; 150+280 overflows.
      final RelativeRect anchor = RelativeRect.fromLTRB(
        150,
        8,
        400 - 182,
        900 - 40,
      );

      final Offset origin = resolveAnchoredOverlayMenuOffset(
        anchor: anchor,
        overlaySize: overlaySize,
        menuSize: menuSize,
        textDirection: TextDirection.ltr,
        screenPadding: 8,
      );

      expect(origin.dx, 400 - 280 - 8);
    });
  });

  group('AnchoredOverlayMenu', () {
    testWidgets(
      'parent rebuild while menu open does not call markNeedsBuild during build',
      (WidgetTester tester) async {
        final AnchoredOverlayMenuController controller =
            AnchoredOverlayMenuController();
        addTearDown(controller.dispose);

        var menuLabel = 'v1';
        late StateSetter setParentState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  setParentState = setState;
                  return AnchoredOverlayMenu(
                    controller: controller,
                    menuBuilder: (VoidCallback hideMenu) => Text(menuLabel),
                    child: TextButton(
                      onPressed: controller.toggleMenu,
                      child: const Text('open'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pump();
        expect(find.text('v1'), findsOneWidget);

        // Comic detail header rebuilds while overlay is open (e.g. scan busy
        // flag). didUpdateWidget must not mark OverlayEntry dirty mid-build.
        setParentState(() => menuLabel = 'v2');
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Content refresh is deferred to the next frame.
        await tester.pump();
        expect(find.text('v2'), findsOneWidget);
      },
    );
  });

  group('anchoredOverlayMenuRect', () {
    testWidgets(
      'uses overlay-local coords so sidebar inset is not double-counted',
      (WidgetTester tester) async {
        late RelativeRect rect;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(
                  builder: (BuildContext context) {
                    return Row(
                      children: <Widget>[
                        const SizedBox(
                          width: 256,
                          child: ColoredBox(color: Colors.grey),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Builder(
                              builder: (BuildContext buttonContext) {
                                return GestureDetector(
                                  onTap: () {
                                    final RenderBox button =
                                        buttonContext.findRenderObject()!
                                            as RenderBox;
                                    final RenderBox overlay =
                                        Overlay.of(
                                              buttonContext,
                                            ).context.findRenderObject()!
                                            as RenderBox;
                                    rect = anchoredOverlayMenuRect(
                                      button: button,
                                      overlay: overlay,
                                      position:
                                          AnchoredOverlayMenuPosition.over,
                                    );
                                  },
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: ColoredBox(color: Colors.blue),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        // Button is immediately after 256px sidebar, top-left of content.
        expect(rect.left, 256);
        expect(rect.top, 0);
      },
    );
  });
}
