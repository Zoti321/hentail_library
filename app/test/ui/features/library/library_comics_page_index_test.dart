import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:test/test.dart';

class _ComicsSortRevision extends Notifier<int> {
  @override
  int build() => 0;
}

final _comicsSortRevisionProvider = NotifierProvider<_ComicsSortRevision, int>(
  _ComicsSortRevision.new,
);

void main() {
  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        allSeriesProvider.overrideWith((Ref ref) async => <Series>[]),
        libraryComicsTabSortOptionProvider.overrideWith((Ref ref) {
          final int revision = ref.watch(_comicsSortRevisionProvider);
          return revision == 0
              ? kLibraryDefaultSortOption
              : LibraryComicSortOption(descending: true);
        }),
      ],
    );
  }

  test('page index resets when comics sort changes', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    expect(container.read(libraryComicsPageIndexProvider), 1);
    container.read(libraryComicsPageIndexProvider.notifier).setPage(4);
    expect(container.read(libraryComicsPageIndexProvider), 4);

    container.read(_comicsSortRevisionProvider.notifier).state = 1;
    expect(container.read(libraryComicsPageIndexProvider), 1);
  });

  test('display target change does not reset comics page index', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    container.read(libraryComicsPageIndexProvider.notifier).setPage(4);
    container
        .read(libraryQueryIntentProvider.notifier)
        .setDisplayTarget(LibraryDisplayTarget.series);
    expect(container.read(libraryComicsPageIndexProvider), 4);
  });

  test('query key change does not mutate page index during provider read', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    container.read(libraryComicsPageIndexProvider.notifier).setPage(2);
    expect(() {
      container.read(_comicsSortRevisionProvider.notifier).state = 1;
      container.read(libraryComicsPageIndexProvider);
    }, returnsNormally);
    expect(container.read(libraryComicsPageIndexProvider), 1);
  });
}
