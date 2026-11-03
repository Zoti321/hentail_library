import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;
import 'package:hentai_library/src/rust/api/comic_trash.dart' as rust;

const String _kRemoteLibraryKind = 'remote';

comic_rust.PageRequestDto mapTrashPageRequest({
  required int page,
  required int pageSize,
}) {
  return comic_rust.PageRequestDto(page: page, pageSize: pageSize);
}

/// Summary FRB 行 → 域 [Comic]（列表所需字段；facet 保持默认空）。
Comic _comicFromTrashedSummary(rust.TrashedComicFrbDto dto) {
  return Comic(
    comicId: dto.comicId,
    path: dto.path,
    resourceType: ResourceType.values.byName(dto.resourceType),
    resourceSize: dto.resourceSize.toInt(),
    createdAt: comicTimestampFromMs(dto.createdAt.toInt()),
    lastUpdatedAt: comicTimestampFromMs(dto.lastUpdatedAt.toInt()),
    title: dto.title,
    pageCount: dto.pageCount,
  );
}

TrashedComic mapTrashedComic(rust.TrashedComicFrbDto dto) {
  return (
    comic: _comicFromTrashedSummary(dto),
    deletedAt: comicTimestampFromMs(dto.deletedAt.toInt()),
    libraryName: dto.libraryName,
    isRemote: dto.libraryKind == _kRemoteLibraryKind,
  );
}

PagedResult<TrashedComic> mapTrashedComicsPage(
  rust.PagedTrashedComicResultFrbDto page,
) {
  return PagedResult<TrashedComic>(
    items: page.items.map(mapTrashedComic).toList(),
    totalCount: page.totalCount.toInt(),
    page: page.page,
    pageSize: page.pageSize,
  );
}

TrashedComicCounts mapTrashedComicCounts(rust.TrashedComicCountsFrbDto dto) {
  return (
    total: dto.total.toInt(),
    local: dto.local.toInt(),
    remote: dto.remote.toInt(),
  );
}

ComicPurgeResult mapComicPurgeResult(rust.ComicPurgeResultFrbDto dto) {
  return (
    succeeded: dto.succeeded,
    failed: dto.failed,
    errorSamples: List<String>.unmodifiable(dto.errorSamples),
  );
}
