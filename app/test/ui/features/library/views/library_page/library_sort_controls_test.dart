import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_expand_by_series_controls.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_sort_controls.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../support/fakes/author_repository_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('expand by series disables comics sort taps until turned off', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        libraryDisplayTargetProvider.overrideWith(
          (Ref ref) => LibraryDisplayTarget.comics,
        ),
        authorRepoProvider.overrideWithValue(const EmptyAuthorRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryComicFiltersProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: Column(
              children: <Widget>[
                LibraryExpandBySeriesControls(),
                LibrarySortControls(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('按系列展开'), findsOneWidget);

    await tester.tap(find.text('添加时间'));
    await tester.pumpAndSettle();

    LibraryComicSortOption sort = (await container.read(
      libraryComicFiltersProvider.future,
    )).sortOption;
    expect(sort.field, LibraryComicSortField.title);

    await tester.tap(find.text('按系列展开'));
    await tester.pumpAndSettle();
    expect(
      (await container.read(libraryComicFiltersProvider.future)).expandBySeries,
      isFalse,
    );

    await tester.tap(find.text('添加时间'));
    await tester.pumpAndSettle();

    sort = (await container.read(
      libraryComicFiltersProvider.future,
    )).sortOption;
    expect(sort.field, LibraryComicSortField.createdAt);
  });
}
