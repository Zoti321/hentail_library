import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_top_bar.dart';

import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('top bar action GhostButtons share unified size 32', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            ReaderTopBar(
              showControls: true,
              title: 'Chrome size contract',
              readerFullscreen: false,
              onExit: () async {},
              onToggleFullscreen: () async {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Iterable<GhostButton> actions = tester.widgetList<GhostButton>(
      find.byType(GhostButton),
    );
    expect(actions, isNotEmpty);
    for (final GhostButton button in actions) {
      expect(button.size, kReaderTopBarActionSize);
    }
  });
}
