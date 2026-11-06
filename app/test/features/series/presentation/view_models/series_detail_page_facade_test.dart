import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_facade_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_jump.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fakes/revision_throttle_test_fakes.dart';

class _FakeLibraryRevision extends LibraryRevisionNotifier {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

class _FakeSeriesRepo implements SeriesRepository {
  @override
  Future<PagedResult<SeriesComicPageItem>> fetchComicsPage({
    required String seriesId,
    required PageRequest request,
  }) async {
    final List<SeriesComicPageItem> items = List<SeriesComicPageItem>.generate(
      request.pageSize,
      (int index) {
        final int n = (request.page - 1) * request.pageSize + index;
        return (
          comic: Comic(
            comicId: 'c-$n',
            path: '/c-$n',
            resourceType: ResourceType.dir,
            resourceSize: 0,
            createdAt: DateTime.utc(2024),
            lastUpdatedAt: DateTime.utc(2024),
            title: 'Comic $n',
            pageCount: 10,
          ),
          sortOrder: n.toDouble(),
          sortOrderLocked: false,
        );
      },
    );
    return PagedResult<SeriesComicPageItem>(
      items: items,
      page: request.page,
      pageSize: request.pageSize,
      totalCount: 120,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...sharedLibraryStateOverrides(),
        ...bootstrapCompositionOverrides(),
        ...idleRevisionThrottleOverrides(),
        libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
        seriesRepoProvider.overrideWith((Ref ref) => _FakeSeriesRepo()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(seriesDetailPageFacadeProvider('series-1'), (_, _) {});
    return container;
  }

  test('jumpPage moves the series detail catalog through the facade', () async {
    final ProviderContainer container = createContainer();
    await container.read(
      seriesDetailComicsCatalogControllerProvider('series-1').future,
    );

    expect(container.read(seriesDetailPageFacadeProvider('series-1')).page, 1);

    container
        .read(seriesDetailPageFacadeProvider('series-1').notifier)
        .jumpPage(PageJump.next);
    await container.read(
      seriesDetailComicsCatalogControllerProvider('series-1').future,
    );

    expect(container.read(seriesDetailPageFacadeProvider('series-1')).page, 2);
  });
}
