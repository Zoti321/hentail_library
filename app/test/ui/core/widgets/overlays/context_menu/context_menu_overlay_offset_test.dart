import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/app_title_bar.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/common.dart';

/// ShellRoute layout: in-app title bar above a nested [Navigator]/[Overlay].
/// [ContextMenuCommon.show] must map global pointer coords into overlay space.
void main() {
  const Key menuKey = Key('menu-panel');
  const Size surface = Size(800, 600);
  const Offset tapInContent = Offset(200, 120);

  Future<void> pumpShell({
    required WidgetTester tester,
    required bool showTitleBar,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              if (showTitleBar)
                const SizedBox(
                  height: AppTitleBar.height,
                  child: ColoredBox(color: Colors.grey),
                ),
              Expanded(
                child: Navigator(
                  onGenerateRoute: (RouteSettings settings) {
                    return MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return Center(
                          child: GestureDetector(
                            key: const Key('hit-target'),
                            onSecondaryTapUp: (TapUpDetails details) {
                              ContextMenuCommon.show(
                                context,
                                position: details.globalPosition,
                                width: 100,
                                height: 40,
                                builder: (VoidCallback onClose) => SizedBox(
                                  key: menuKey,
                                  width: 100,
                                  height: 40,
                                  child: const ColoredBox(color: Colors.red),
                                ),
                              );
                            },
                            child: const SizedBox(
                              width: 400,
                              height: 400,
                              child: ColoredBox(color: Colors.blue),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Offset> openMenuAtContentLocal(
    WidgetTester tester,
    Offset localInContent,
  ) async {
    final Offset global =
        tester.getTopLeft(find.byKey(const Key('hit-target'))) + localInContent;
    await tester.tapAt(global, buttons: kSecondaryButton);
    await tester.pump();
    return global;
  }

  testWidgets(
    'with title bar, menu top-left matches secondary-tap global position',
    (WidgetTester tester) async {
      await pumpShell(tester: tester, showTitleBar: true);

      final Offset cursor = await openMenuAtContentLocal(tester, tapInContent);
      final Offset menuTopLeft = tester.getTopLeft(find.byKey(menuKey));

      expect(menuTopLeft, offsetMoreOrLessEquals(cursor, epsilon: 0.5));
    },
  );

  testWidgets(
    'without title bar (fullscreen-like), menu top-left matches cursor',
    (WidgetTester tester) async {
      await pumpShell(tester: tester, showTitleBar: false);

      final Offset cursor = await openMenuAtContentLocal(tester, tapInContent);
      final Offset menuTopLeft = tester.getTopLeft(find.byKey(menuKey));

      expect(menuTopLeft, offsetMoreOrLessEquals(cursor, epsilon: 0.5));
    },
  );
}
