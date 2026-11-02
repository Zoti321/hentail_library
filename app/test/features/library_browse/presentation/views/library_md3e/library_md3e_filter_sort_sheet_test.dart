import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_grouping.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_needs_metadata_only.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_filter_sort_sheet.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_sort_option.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _FixedComicFilters extends LibraryComicFiltersNotifier {
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
}

Future<void> _pumpSheetTrigger(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
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
        libraryComicFiltersProvider.overrideWith(_FixedComicFilters.new),
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
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () => Md3eLibraryFilterSortSheet.show(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final AppLocalizations l10n = AppLocalizationsZh();

  testWidgets('opens the filter and sort sheet with both sections', (
    WidgetTester tester,
  ) async {
    await _pumpSheetTrigger(tester);

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryAgeRestrictionFilter), findsOneWidget);
    expect(find.text(l10n.librarySortSection), findsOneWidget);
  });
}
