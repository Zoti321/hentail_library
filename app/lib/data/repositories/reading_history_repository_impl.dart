import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
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
      guardFrbSync(
        () => rust.recordReadingFrb(history: toReadingHistoryDto(history)),
        fallbackMessage: '记录阅读进度失败',
      );
    } catch (e, st) {
      logError(
        AppLog.dataRepo('reading_history'),
        '记录阅读进度失败，comicId=${history.comicId}',
        e,
        st,
      );
      if (e is AppException) {
        rethrow;
      }
      throw AppException('记录阅读进度失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<entity.ReadingHistory?> getByComicId(String comicId) async {
    final rust.ReadingHistoryDto? row = guardFrbSync(
      () => rust.getReadingByComicIdFrb(comicId: comicId),
      fallbackMessage: '读取阅读进度失败',
    );
    return row == null ? null : mapReadingHistoryDto(row);
  }

  @override
  Stream<List<entity.ReadingHistory>> watchAllHistory() {
    return guardFrbStream(
      () => rust.watchReadingHistoriesFrb().map(
        (List<rust.ReadingHistoryDto> rows) =>
            rows.map(mapReadingHistoryDto).toList(growable: false),
      ),
      fallbackMessage: '监听阅读历史失败',
    );
  }

  @override
  Future<PagedResult<entity.ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  }) async {
    final String? normalizedKeyword = _normalizeKeyword(keyword);
    final rust.PagedReadingHistoryDto page = guardFrbSync(
      () => rust.fetchReadingPageFrb(
        page: request.page,
        pageSize: request.pageSize,
        keyword: normalizedKeyword,
      ),
      fallbackMessage: '读取阅读历史失败',
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
      final rust.PagedReadingHistoryDto adjusted = guardFrbSync(
        () => rust.fetchReadingPageFrb(
          page: effectivePage,
          pageSize: request.pageSize,
          keyword: normalizedKeyword,
        ),
        fallbackMessage: '读取阅读历史失败',
      );
      return mapPagedReadingHistory(adjusted, effectivePage, request.pageSize);
    }
    return mapPagedReadingHistory(page, effectivePage, request.pageSize);
  }

  String? _normalizeKeyword(String? keyword) {
    final String? trimmed = keyword?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  Future<void> deleteByComicId(String comicId) async {
    try {
      guardFrbSync(
        () => rust.deleteReadingByComicIdFrb(comicId: comicId),
        fallbackMessage: '删除阅读历史失败',
      );
    } catch (e, st) {
      logError(
        AppLog.dataRepo('reading_history'),
        '删除阅读历史失败，comicId=$comicId',
        e,
        st,
      );
      if (e is AppException) {
        rethrow;
      }
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
      guardFrbSync(
        () => rust.deleteReadingByComicIdsFrb(comicIds: ids),
        fallbackMessage: '批量删除阅读历史失败',
      );
    } catch (e, st) {
      logError(
        AppLog.dataRepo('reading_history'),
        '批量删除阅读历史失败',
        e,
        st,
      );
      if (e is AppException) {
        rethrow;
      }
      throw AppException('批量删除阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      guardFrbSync(
        () => rust.clearAllReadingFrb(),
        fallbackMessage: '清空阅读历史失败',
      );
    } catch (e, st) {
      logError(AppLog.dataRepo('reading_history'), '清空阅读历史失败', e, st);
      if (e is AppException) {
        rethrow;
      }
      throw AppException('清空阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> clearExpiredHistory() async {
    // 365 天清理：暂由 Rust 侧与 Drift 行为对齐的 SQL 在后续 slice 补齐；当前无 UI 调用。
  }
}
