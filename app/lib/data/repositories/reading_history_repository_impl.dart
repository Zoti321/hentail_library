import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/adapters/history_frb_mapper.dart';
import 'package:hentai_library/domain/models/models.dart' as entity;
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/src/rust/api/history.dart' as rust;

class ReadingHistoryRepositoryImpl implements ReadingHistoryRepository {
  const ReadingHistoryRepositoryImpl();

  @override
  Future<void> recordReading(entity.ReadingHistory history) async {
    try {
      rust.recordReadingFrb(history: toReadingHistoryDto(history));
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 记录阅读进度失败，comicId=${history.comicId}',
      );
      throw AppException('记录阅读进度失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<entity.ReadingHistory?> getByComicId(String comicId) async {
    final rust.ReadingHistoryDto? row = rust.getReadingByComicIdFrb(
      comicId: comicId,
    );
    return row == null ? null : mapReadingHistoryDto(row);
  }

  @override
  Stream<List<entity.ReadingHistory>> watchAllHistory() {
    return rust.watchReadingHistoriesFrb().map(
      (List<rust.ReadingHistoryDto> rows) =>
          rows.map(mapReadingHistoryDto).toList(growable: false),
    );
  }

  @override
  Future<PagedResult<entity.ReadingHistory>> fetchHistoryPage(
    PageRequest request,
  ) async {
    final rust.PagedReadingHistoryDto page = rust.fetchReadingPageFrb(
      page: request.page,
      pageSize: request.pageSize,
    );
    if (page.totalCount.toInt() <= 0) {
      return PagedResult<entity.ReadingHistory>(
        items: const <entity.ReadingHistory>[],
        totalCount: 0,
        page: 1,
        pageSize: request.pageSize,
      );
    }
    final int totalPages =
        (page.totalCount.toInt() + request.pageSize - 1) ~/ request.pageSize;
    final int effectivePage = request.page > totalPages
        ? totalPages
        : request.page;
    if (effectivePage != request.page) {
      final rust.PagedReadingHistoryDto adjusted = rust.fetchReadingPageFrb(
        page: effectivePage,
        pageSize: request.pageSize,
      );
      return mapPagedReadingHistory(adjusted, effectivePage, request.pageSize);
    }
    return mapPagedReadingHistory(page, effectivePage, request.pageSize);
  }

  @override
  Future<void> deleteByComicId(String comicId) async {
    try {
      rust.deleteReadingByComicIdFrb(comicId: comicId);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 删除阅读历史失败，comicId=$comicId',
      );
      throw AppException('删除阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteByComicIds(Iterable<String> comicIds) async {
    try {
      final List<String> ids = comicIds.toList(growable: false);
      if (ids.isEmpty) {
        return;
      }
      rust.deleteReadingByComicIdsFrb(comicIds: ids);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[READING_HISTORY_REPO] 批量删除阅读历史失败');
      throw AppException('批量删除阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      rust.clearAllReadingFrb();
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[READING_HISTORY_REPO] 清空阅读历史失败');
      throw AppException('清空阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> clearExpiredHistory() async {
    // 365 天清理：暂由 Rust 侧与 Drift 行为对齐的 SQL 在后续 slice 补齐；当前无 UI 调用。
  }
}
