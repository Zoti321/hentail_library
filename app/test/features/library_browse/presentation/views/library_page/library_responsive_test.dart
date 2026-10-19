import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/chrome/content_switcher_bottom_bar.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/meta_chip.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_filter_sort_drawer.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_pinned_header.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_refresh_command_port.dart';
import 'package:hentai_library/shared/domain/library/library_scan_command_port.dart';
import 'package:hentai_library/shared/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';

void main() {
  group('Library responsive layout', () {
    testWidgets('compact toolbar shows active count chip without header tabs', (
      WidgetTester tester,
    ) async {
      await _pumpHeaderToolbar(
        tester,
        viewportWidth: 360,
        layoutTier: LibraryLayoutTier.compact,
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('漫画库'));
      expect(title.style?.fontSize, 18);
      expect(find.byType(CountDigitChip), findsOneWidget);
      expect(find.byType(MetaChip), findsNothing);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('12 本'), findsNothing);
      expect(find.text('3 个系列'), findsNothing);
      expect(find.byType(LibraryDisplayTargetTabs), findsNothing);
      expect(find.byType(ContentSwitcherBottomBar), findsOneWidget);
      expect(find.text('漫画'), findsOneWidget);
      expect(find.text('系列'), findsOneWidget);
    });

    testWidgets('medium toolbar shows count chips and medium title size', (
      WidgetTester tester,
    ) async {
      await _pumpHeaderToolbar(
        tester,
        viewportWidth: 700,
        layoutTier: LibraryLayoutTier.medium,
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('漫画库'));
      expect(title.style?.fontSize, 22);
      expect(find.byType(MetaChip), findsNWidgets(2));
      expect(find.byType(LibraryDisplayTargetTabs), findsOneWidget);
      expect(find.byType(ContentSwitcherBottomBar), findsNothing);
    });

    testWidgets('expanded toolbar keeps desktop title size', (
      WidgetTester tester,
    ) async {
      await _pumpHeaderToolbar(
        tester,
        viewportWidth: 1200,
        layoutTier: LibraryLayoutTier.expanded,
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('漫画库'));
      expect(title.style?.fontSize, 26);
    });

    testWidgets('compact filter sort drawer uses wide responsive width', (
      WidgetTester tester,
    ) async {
      const double viewportWidth = 360;
      tester.view.physicalSize = const Size(viewportWidth, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _dictionaryStateTestOverrides(),
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(Brightness.light),
            home: MediaQuery(
              data: const MediaQueryData(size: Size(viewportWidth, 800)),
              child: const Scaffold(body: LibraryFilterSortDrawer()),
            ),
          ),
        ),
      );
      await tester.pump();

      final Drawer drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(
        drawer.width,
        libraryFilterSortDrawerWidthForViewport(viewportWidth),
      );
      expect(drawer.width!, greaterThanOrEqualTo(viewportWidth * 0.5));
    });
  });

  group('libraryGridDelegateForTokens', () {
    test('returns tiered grid metrics', () {
      final AppThemeTokens tokens = buildAppTheme(
        Brightness.light,
      ).extension<AppThemeTokens>()!;

      final SliverGridDelegateWithMaxCrossAxisExtent compactDelegate =
          libraryGridDelegateForTokens(tokens, LibraryLayoutTier.compact)
              as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(compactDelegate.maxCrossAxisExtent, 168);
      expect(compactDelegate.crossAxisSpacing, 12);
      expect(compactDelegate.mainAxisSpacing, 12);

      final SliverGridDelegateWithMaxCrossAxisExtent expandedDelegate =
          libraryGridDelegateForTokens(tokens, LibraryLayoutTier.expanded)
              as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(expandedDelegate.maxCrossAxisExtent, 200);
      expect(expandedDelegate.crossAxisSpacing, 16);
      expect(expandedDelegate.mainAxisSpacing, 16);
    });
  });
}

Future<void> _pumpHeaderToolbar(
  WidgetTester tester, {
  required double viewportWidth,
  required LibraryLayoutTier layoutTier,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final double horizontalPadding = libraryContentHorizontalPadding(layoutTier);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _libraryHeaderTestOverrides(),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: viewportWidth,
            child: LibraryPageHeaderSection(
              layoutTier: layoutTier,
              horizontalPadding: horizontalPadding,
              onOpenFilterSort: () {},
            ),
          ),
          bottomNavigationBar: libraryUsesContentSwitcherBottomBar(layoutTier)
              ? const LibraryDisplayTargetBottomBar()
              : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _libraryHeaderTestOverrides() {
  return <Override>[
    libraryDisplayedComicCountProvider.overrideWith((Ref ref) => 12),
    libraryDisplayedSeriesCountProvider.overrideWith((Ref ref) => 3),
    libraryDisplayTargetProvider.overrideWith(
      (Ref ref) => LibraryDisplayTarget.comics,
    ),
    libraryActiveFilterSortIsCustomizedProvider.overrideWith(
      (Ref ref) => false,
    ),
    libraryActivePageSizeProvider.overrideWith((Ref ref) => 20),
    ..._dictionaryStateTestOverrides(),
  ];
}

List<Override> _dictionaryStateTestOverrides() {
  return <Override>[
    ...bootstrapCompositionOverrides(),
    libraryScanActivityStateProvider.overrideWithValue((
      running: false,
      scanMode: ScanMode.incremental,
    )),
    libraryMetadataRefreshRunningStateProvider.overrideWithValue(false),
    libraryScanCommandPortProvider.overrideWithValue(
      _NoopLibraryScanCommandPort(),
    ),
    libraryMetadataRefreshCommandPortProvider.overrideWithValue(
      _NoopLibraryMetadataRefreshCommandPort(),
    ),
    libraryTagDictionaryStateProvider.overrideWithValue(
      const AsyncValue<List<Tag>>.data(<Tag>[]),
    ),
    libraryAuthorDictionaryStateProvider.overrideWithValue(
      const AsyncValue<List<Author>>.data(<Author>[]),
    ),
  ];
}

class _NoopLibraryScanCommandPort implements LibraryScanCommandPort {
  @override
  Future<void> start({
    ScanMode mode = ScanMode.incremental,
    bool syncAll = false,
    bool silent = false,
  }) async {}

  @override
  void cancel() {}
}

class _NoopLibraryMetadataRefreshCommandPort
    implements LibraryMetadataRefreshCommandPort {
  @override
  Future<void> refreshComic({
    required String comicId,
    required String title,
  }) async {}

  @override
  Future<MetadataRefreshBatchResult> refreshSeries({
    required String seriesId,
    required String name,
  }) async {
    return (
      succeeded: 0,
      failed: 0,
      cancelled: false,
      skipped: false,
      skipMessage: null,
    );
  }

  @override
  void cancel() {}

  @override
  bool isRefreshingSeries(String seriesId) => false;

  @override
  bool get running => false;
}
