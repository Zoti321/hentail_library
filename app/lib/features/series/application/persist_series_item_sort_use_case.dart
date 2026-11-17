import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';

/// 在 Comic 元数据保存路径中，按草稿与种子差异写入 Series 成员排序 / 锁。
///
/// 返回是否实际写库。写库成功后发布 [LibraryCatalogChanged]（ADR-0039）。
/// [updateSeriesItemSortOrder] 由 core 在写 order 时自动
/// `sortOrderLocked=true`。改 order 后不得用草稿「关」锁去抵消该自动锁；
/// 仅「未改 order、只改锁」时写锁。
class PersistSeriesItemSortUseCase {
  const PersistSeriesItemSortUseCase({
    required this._repository,
    required this._events,
  });

  final SeriesRepository _repository;
  final DomainEventPublisher _events;

  Future<bool> call({
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
      await _repository.updateSeriesItemSortOrder(
        seriesId: seed.seriesId,
        comicId: comicId,
        sortOrder: sortOrder,
      );
      // core 写 order 即 lock=true；草稿锁仍为关时不得再解锁抵消。
    } else if (lockChanged) {
      await _repository.setSeriesItemSortOrderLocked(
        seriesId: seed.seriesId,
        comicId: comicId,
        locked: draftLocked,
      );
    }
    _events.publish(
      const LibraryCatalogChanged(CatalogChangeSource.libraryAdmin),
    );
    return true;
  }
}
