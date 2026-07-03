import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:test/test.dart';

void main() {
  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        allSeriesProvider.overrideWith((Ref ref) async => <Series>[]),
      ],
    );
  }

  test('page index resets when query key changes', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    expect(container.read(libraryComicsPageIndexProvider), 1);
    container.read(libraryComicsPageIndexProvider.notifier).setPage(4);
    expect(container.read(libraryComicsPageIndexProvider), 4);

    container
        .read(libraryQueryIntentProvider.notifier)
        .setDisplayTarget(LibraryDisplayTarget.comics);
    expect(container.read(libraryComicsPageIndexProvider), 1);
  });

  test('query key change does not mutate page index during provider read', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    container.read(libraryComicsPageIndexProvider.notifier).setPage(2);
    expect(() {
      container
          .read(libraryQueryIntentProvider.notifier)
          .setDisplayTarget(LibraryDisplayTarget.series);
      container.read(libraryComicsPageIndexProvider);
    }, returnsNormally);
    expect(container.read(libraryComicsPageIndexProvider), 1);
  });
}
