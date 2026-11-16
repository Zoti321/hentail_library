import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_design_system_app.dart';

void main() {
  for (final expressive in [false, true]) {
    testWidgets(
      'restored scroll exposes localized button and reduced motion jumps to top ($expressive)',
      (tester) async {
        final controller = ScrollController(initialScrollOffset: 2000);
        addTearDown(controller.dispose);
        await pumpDesignSystemApp(
          tester,
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  ListView.builder(
                    controller: controller,
                    itemCount: 100,
                    itemBuilder: (_, i) =>
                        SizedBox(height: 80, child: Text('$i')),
                  ),
                  if (expressive)
                    ExpressiveLibraryScrollToTopButton(
                      scrollController: controller,
                      horizontalPadding: 16,
                    )
                  else
                    LibraryScrollToTopButton(
                      scrollController: controller,
                      isDrawerOpen: false,
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();
        await tester.pump();
        final button = find.bySemanticsLabel('Back to top');
        expect(button, findsWidgets);
        await tester.tap(button.first);
        await tester.pump();
        expect(controller.offset, 0);
        await tester.pumpAndSettle();
        expect(
          tester.semantics.simulatedAccessibilityTraversal(),
          isNot(contains(isSemantics(label: 'Back to top'))),
        );
        semantics.dispose();
      },
    );
  }
}
