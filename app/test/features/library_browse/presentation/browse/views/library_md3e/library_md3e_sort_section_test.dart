import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_grouping.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_needs_metadata_only.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library_md3e/library_md3e_sort_section.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_sort_option.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _RecordingComicFilters extends LibraryComicFiltersNotifier {
  _RecordingComicFilters(this.sortCalls, this.grouping);

  final List<LibraryComicSortField> sortCalls;
  final LibraryComicGrouping grouping;

  @override
  Future<LibraryComicFiltersState> build() async => LibraryComicFiltersState(
    ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
    mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
    tagFilter: const LibraryMetadataFilterSelection(),
    authorFilter: const LibraryMetadataFilterSelection(),
    needsMetadataOnly: LibraryNeedsMetadataOnly.defaultValue,
    grouping: grouping,
    sortOption: LibraryComicSortOption(),
  );

  @override
  Future<void> setSortField(LibraryComicSortField field) async {
    sortCalls.add(field);
  }
}

Future<void> _pumpSortSection(
  WidgetTester tester, {
  required List<LibraryComicSortField> sortCalls,
  LibraryComicGrouping grouping = LibraryComicGrouping.none,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        libraryDisplayTargetProvider.overrideWithValue(
          LibraryDisplayTarget.comics,
        ),
        libraryComicFiltersProvider.overrideWith(
          () => _RecordingComicFilters(sortCalls, grouping),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SingleChildScrollView(child: Md3eLibrarySortSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final AppLocalizations l10n = AppLocalizationsZh();

  testWidgets('comics tab lists the group toggle and every comic sort field', (
    WidgetTester tester,
  ) async {
    await _pumpSortSection(tester, sortCalls: <LibraryComicSortField>[]);

    expect(find.text(l10n.libraryExpandBySeries), findsOneWidget);
    for (final LibraryComicSortField field in LibraryComicSortField.values) {
      expect(find.text(l10n.libraryComicSortFieldLabel(field)), findsOneWidget);
    }
  });

  testWidgets('tapping an implemented comic sort field selects it', (
    WidgetTester tester,
  ) async {
    final List<LibraryComicSortField> sortCalls = <LibraryComicSortField>[];
    await _pumpSortSection(tester, sortCalls: sortCalls);

    final LibraryComicSortField field = LibraryComicSortField.values.firstWhere(
      (LibraryComicSortField f) => f.isImplemented,
    );
    await tester.tap(find.text(l10n.libraryComicSortFieldLabel(field)));
    await tester.pumpAndSettle();

    expect(sortCalls, <LibraryComicSortField>[field]);
  });

  testWidgets('group-by-series disables comic sort selection', (
    WidgetTester tester,
  ) async {
    final List<LibraryComicSortField> sortCalls = <LibraryComicSortField>[];
    await _pumpSortSection(
      tester,
      sortCalls: sortCalls,
      grouping: LibraryComicGrouping.bySeries,
    );

    final LibraryComicSortField field = LibraryComicSortField.values.firstWhere(
      (LibraryComicSortField f) => f.isImplemented,
    );
    await tester.tap(find.text(l10n.libraryComicSortFieldLabel(field)));
    await tester.pumpAndSettle();

    expect(sortCalls, isEmpty);
  });
}
