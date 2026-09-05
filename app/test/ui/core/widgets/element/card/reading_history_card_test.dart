import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/reading_history_card.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets(
    'hover keeps border subtle and animates card shadow like catalog cards',
    (WidgetTester tester) async {
      final ThemeData theme = buildAppTheme(Brightness.light);
      final HentaiColorScheme h = theme.colorScheme.hentai;

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            comicCoverProvider('comic-1').overrideWith(_NoCoverComicCover.new),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  height: 120,
                  child: ReadingHistoryCard(
                    comicId: 'comic-1',
                    title: 'Sample comic',
                    lastReadTime: DateTime(2026, 1, 1),
                    pageIndex: 12,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      BoxDecoration decoration = _cardDecoration(tester);
      expect(_borderColor(decoration), h.borderSubtle);
      expect(decoration.boxShadow!.single.color, h.cardShadow);
      expect(decoration.boxShadow!.single.blurRadius, 2);

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(ReadingHistoryCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      decoration = _cardDecoration(tester);
      expect(_borderColor(decoration), h.borderSubtle);
      expect(decoration.boxShadow!.single.color, h.cardShadowHover);
      expect(decoration.boxShadow!.single.blurRadius, 4);
    },
  );

  testWidgets('Tab focus lifts card chrome; pointer tap restores idle', (
    WidgetTester tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    final ThemeData theme = buildAppTheme(Brightness.light);
    final HentaiColorScheme h = theme.colorScheme.hentai;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          comicCoverProvider('comic-1').overrideWith(_NoCoverComicCover.new),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 120,
                child: ReadingHistoryCard(
                  comicId: 'comic-1',
                  title: 'Sample comic',
                  lastReadTime: DateTime(2026, 1, 1),
                  pageIndex: 12,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    BoxDecoration decoration = _cardDecoration(tester);
    expect(decoration.color, theme.colorScheme.surface);
    expect(decoration.boxShadow!.single.color, h.cardShadow);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    decoration = _cardDecoration(tester);
    expect(decoration.color, theme.colorScheme.surfaceContainer);
    expect(decoration.boxShadow!.single.color, h.cardShadowHover);

    await tester.tap(find.byType(ReadingHistoryCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<ReadingHistoryCard>(),
      isNull,
    );
    decoration = _cardDecoration(tester);
    expect(decoration.color, theme.colorScheme.surface);
    expect(decoration.boxShadow!.single.color, h.cardShadow);
  });

  testWidgets('wraps card chrome in a RepaintBoundary', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = buildAppTheme(Brightness.light);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          comicCoverProvider('comic-1').overrideWith(_NoCoverComicCover.new),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 120,
                child: ReadingHistoryCard(
                  comicId: 'comic-1',
                  title: 'Sample comic',
                  lastReadTime: DateTime(2026, 1, 1),
                  pageIndex: 12,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ReadingHistoryCard),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });
}

BoxDecoration _cardDecoration(WidgetTester tester) {
  final AnimatedContainer container = tester.widget(
    find.descendant(
      of: find.byType(ReadingHistoryCard),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

Color _borderColor(BoxDecoration decoration) {
  return (decoration.border! as Border).top.color;
}

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();

  @override
  void ensureLoaded({ThumbnailPriority priority = ThumbnailPriority.high}) {}
}
