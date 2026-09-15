import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_bottom_bar.dart';
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

  testWidgets('bottom bar panel uses full width under compact breakpoint', (
    WidgetTester tester,
  ) async {
    const Size compactViewport = Size(AppLayoutBreakpoints.compact - 1, 800);
    await tester.binding.setSurfaceSize(compactViewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      home: MediaQuery(
        data: const MediaQueryData(size: compactViewport),
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              ReaderBottomBar(
                showControls: true,
                currentIndex: 1,
                totalPages: 10,
                readerAutoPlayEnabled: false,
                showAutoPlayControls: false,
                onPrevPage: () {},
                onNextPage: () async {},
                onSetIndex: (_) {},
                onReaderAutoPlayEnabledChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ReaderFloatingPanel panel = tester.widget<ReaderFloatingPanel>(
      find.byType(ReaderFloatingPanel),
    );
    expect(panel.width, compactViewport.width);
  });
}
