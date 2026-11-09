import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/domain/ports/series_item_sort_port.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';

/// Comic 元数据保存路径写入 Series 成员排序 / 锁的 Port 实现（#457）。

/// 在 Comic 元数据保存路径中，按草稿与种子差异写入 Series 成员排序 / 锁。
///
/// 返回是否实际写库。写库成功后发布 [LibraryCatalogChanged]（ADR-0039）。
/// [updateSeriesItemSortOrder] 由 core 在写 order 时自动
/// `sortOrderLocked=true`。改 order 后不得用草稿「关」锁去抵消该自动锁；
/// 仅「未改 order、只改锁」时写锁。
Future<bool> persistSeriesItemSortIfChanged({
  required SeriesRepository repo,
  required DomainEventPublisher events,
  required String comicId,
  required SeriesItemMembership seed,
  required double sortOrder,
  required bool draftLocked,
}) async {
  final bool orderChanged = sortOrder != seed.sortOrder;
  final bool lockChanged = draftLocked != seed.sortOrderLocked;
  if (!orderChanged && !lockChanged) {
    return false;
  }

  if (orderChanged) {
    await repo.updateSeriesItemSortOrder(
      seriesId: seed.seriesId,
      comicId: comicId,
      sortOrder: sortOrder,
    );
    // core 写 order 即 lock=true；草稿锁仍为关时不得再解锁抵消。
  } else if (lockChanged) {
    await repo.setSeriesItemSortOrderLocked(
      seriesId: seed.seriesId,
      comicId: comicId,
      locked: draftLocked,
    );
  }
  events.publish(const LibraryCatalogChanged(CatalogChangeSource.libraryAdmin));
  return true;
}

class SeriesItemSortService implements SeriesItemSortPort {
  const SeriesItemSortService({
    required this._repository,
    required this._events,
  });

  final SeriesRepository _repository;
  final DomainEventPublisher _events;

  @override
  Future<bool> persistIfChanged({
    required String comicId,
    required SeriesItemMembership seed,
    required double sortOrder,
    required bool draftLocked,
  }) => persistSeriesItemSortIfChanged(
    repo: _repository,
    events: _events,
    comicId: comicId,
    seed: seed,
    sortOrder: sortOrder,
    draftLocked: draftLocked,
  );
}
