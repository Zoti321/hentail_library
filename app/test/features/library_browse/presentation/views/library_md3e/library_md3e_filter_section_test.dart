import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/library_browse/domain/library_comic_grouping.dart';
import 'package:hentai_library/features/library_browse/domain/library_needs_metadata_only.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_filter_section.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/shared/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _RecordingComicFilters extends LibraryComicFiltersNotifier {
  _RecordingComicFilters(this.ageCalls);

  final List<LibraryAgeRestrictionFilter> ageCalls;

  @override
  Future<LibraryComicFiltersState> build() async => LibraryComicFiltersState(
    ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
    mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
    tagFilter: const LibraryMetadataFilterSelection(),
    authorFilter: const LibraryMetadataFilterSelection(),
    needsMetadataOnly: LibraryNeedsMetadataOnly.defaultValue,
    grouping: LibraryComicGrouping.none,
    sortOption: LibraryComicSortOption(),
  );

  @override
  Future<void> toggleAgeRestrictionOption(
    LibraryAgeRestrictionFilter option,
  ) async {
    ageCalls.add(option);
  }
}

Future<void> _pumpFilterSection(
  WidgetTester tester, {
  required List<LibraryAgeRestrictionFilter> ageCalls,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...bootstrapCompositionOverrides(),
        libraryDisplayTargetProvider.overrideWithValue(
          LibraryDisplayTarget.comics,
        ),
        libraryComicFiltersProvider.overrideWith(
          () => _RecordingComicFilters(ageCalls),
        ),
        libraryTagDictionaryStateProvider.overrideWithValue(
          const AsyncValue<List<Tag>>.data(<Tag>[]),
        ),
        libraryAuthorDictionaryStateProvider.overrideWithValue(
          const AsyncValue<List<Author>>.data(<Author>[]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SingleChildScrollView(child: Md3eLibraryFilterSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final AppLocalizations l10n = AppLocalizationsZh();

  testWidgets('comics tab lists the accordion groups', (
    WidgetTester tester,
  ) async {
    await _pumpFilterSection(tester, ageCalls: <LibraryAgeRestrictionFilter>[]);

    expect(find.text(l10n.libraryAgeRestrictionFilter), findsOneWidget);
    expect(find.text(l10n.libraryMediaTypeFilter), findsOneWidget);
    expect(find.text(l10n.libraryTagFilter), findsOneWidget);
    expect(find.text(l10n.libraryAuthorFilter), findsOneWidget);
    expect(find.text(l10n.libraryOrganizeFilter), findsOneWidget);
    expect(find.text(l10n.librarySerializationStatusFilter), findsNothing);
  });

  testWidgets('expanding age restriction and tapping an option toggles it', (
    WidgetTester tester,
  ) async {
    final List<LibraryAgeRestrictionFilter> ageCalls =
        <LibraryAgeRestrictionFilter>[];
    await _pumpFilterSection(tester, ageCalls: ageCalls);

    await tester.tap(find.text(l10n.libraryAgeRestrictionFilter));
    await tester.pumpAndSettle();

    final LibraryAgeRestrictionFilter option =
        LibraryAgeRestrictionFilter.selectableOptions.first;
    await tester.tap(find.text(l10n.libraryAgeRestrictionFilterLabel(option)));
    await tester.pumpAndSettle();

    expect(ageCalls, <LibraryAgeRestrictionFilter>[option]);
  });
}
