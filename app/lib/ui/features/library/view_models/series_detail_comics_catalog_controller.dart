import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_pagination_engine.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_detail_comics_catalog_controller.g.dart';

@Riverpod(keepAlive: true)
class SeriesDetailComicsCatalogController
    extends _$SeriesDetailComicsCatalogController {
  final CatalogPaginationEngine _pagination = CatalogPaginationEngine();

  int get pageIndex => _pagination.pageIndex;

  @override
  Future<SeriesDetailComicsCatalogState> build(String seriesId) async {
    _syncPaginationWithQueryKey(seriesId);
    return _load(seriesId);
  }

  void _syncPaginationWithQueryKey(String seriesId) {
    _pagination.syncQueryKey((
      seriesId,
      ref.watch(seriesDetailActivePageSizeProvider),
    ));
  }

  Future<SeriesDetailComicsCatalogState> _load(String seriesId) async {
    ref.watch(
      libraryRevisionProvider.select(
        (LibraryRevisionState state) => state.revision,
      ),
    );

    final int pageSize = ref.read(seriesDetailActivePageSizeProvider);
    final PagedResult<Comic> page = await _pagination.fetchPage<Comic>(
      pageSize: pageSize,
      fetch: (PageRequest request) => ref
          .read(seriesRepoProvider)
          .fetchComicsPage(seriesId: seriesId, request: request),
    );

    return SeriesDetailComicsCatalogState(
      items: page.items,
      pagination: LibraryPagination(
        page: page.page,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        isLoading: false,
      ),
    );
  }

  void setPage(int page) {
    if (_pagination.setPage(page)) {
      ref.invalidateSelf();
    }
  }

  void goToFirstPage() {
    if (_pagination.goToFirstPage()) {
      ref.invalidateSelf();
    }
  }

  void goToLastPage(int totalPages) {
    if (_pagination.goToLastPage(totalPages)) {
      ref.invalidateSelf();
    }
  }

  void goToPreviousPage() {
    if (_pagination.goToPreviousPage()) {
      ref.invalidateSelf();
    }
  }

  void goToNextPage(int totalPages) {
    if (_pagination.goToNextPage(totalPages)) {
      ref.invalidateSelf();
    }
  }

  void refresh() {
    _pagination.refresh();
    ref.invalidateSelf();
  }
}

@Riverpod(keepAlive: true)
Future<SeriesComicsMetadata?> seriesComicsMetadata(
  Ref ref,
  String seriesId,
) async {
  ref.watch(
    libraryRevisionProvider.select(
      (LibraryRevisionState state) => state.revision,
    ),
  );
  try {
    return await ref.read(seriesRepoProvider).fetchComicsMetadata(seriesId);
  } on Object {
    return null;
  }
}
