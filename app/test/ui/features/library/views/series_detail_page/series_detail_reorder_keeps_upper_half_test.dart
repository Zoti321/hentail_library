import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_mode.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

class _FakeRevision extends LibraryRevision {
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
    final Comic comic = Comic(
      comicId: 'comic-1',
      path: '/c/1',
      resourceType: ResourceType.dir,
      resourceSize: 0,
      createdAt: DateTime.utc(2024),
      lastUpdatedAt: DateTime.utc(2024),
      title: 'Member One',
      pageCount: 3,
    );
    return PagedResult<SeriesComicPageItem>(
      items: <SeriesComicPageItem>[
        (comic: comic, sortOrder: 1, sortOrderLocked: false),
      ],
      page: 1,
      pageSize: request.pageSize,
      totalCount: 1,
    );
  }

  @override
  Future<SeriesComicsMetadata> fetchComicsMetadata(String seriesId) async {
    return const SeriesComicsMetadata(
      authors: <String>[],
      tags: <String>[],
      parodies: <String>[],
      characters: <String>[],
      languages: <String>[],
      hasR18: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Series reorder mode keeps series name upper half visible', (
    WidgetTester tester,
  ) async {
    final Series series = Series(
      id: 'series-1',
      name: 'Keep Upper Half Series',
      folderPath: '/lib/Keep',
    );
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      overrides: <Override>[
        libraryRevisionProvider.overrideWith(_FakeRevision.new),
        seriesRepoProvider.overrideWith((Ref ref) => _FakeSeriesRepo()),
        seriesComicsMetadataProvider('series-1').overrideWith(
          (Ref ref) async => const SeriesComicsMetadata(
            authors: <String>[],
            tags: <String>[],
            parodies: <String>[],
            characters: <String>[],
            languages: <String>[],
            hasR18: false,
          ),
        ),
      ],
      home: Scaffold(body: SeriesDetail(series: series)),
    );
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(SeriesDetail)),
    );
    container.read(seriesReorderModeProvider('series-1').notifier).enter();
    await tester.pumpAndSettle();

    expect(find.text('Keep Upper Half Series'), findsOneWidget);
    expect(find.byTooltip('退出排序'), findsOneWidget);
    expect(find.text('拖拽排序'), findsOneWidget);
  });
}
