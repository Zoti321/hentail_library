import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/common.dart';

void main() {
  testWidgets('menu top-left matches position when it fits on screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const Offset anchor = Offset(120, 80);
    const Key menuKey = Key('context-menu-panel');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    ContextMenuCommon.show(
                      context,
                      position: anchor,
                      width: 236,
                      height: 152,
                      builder: (VoidCallback onClose) => SizedBox(
                        key: menuKey,
                        width: 236,
                        height: 152,
                        child: const ColoredBox(color: Colors.red),
                      ),
                    );
                  },
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

    final Offset menuTopLeft = tester.getTopLeft(find.byKey(menuKey));
    expect(menuTopLeft, anchor);
  });
}
