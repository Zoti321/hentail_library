import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/features/reading_history/data/mappers/history_frb_mapper.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust_comic;
import 'package:hentai_library/src/rust/api/history.dart' as rust;

class ReadingHistoryRepositoryImpl implements ReadingHistoryRepository {
  const ReadingHistoryRepositoryImpl();

  @override
  Future<void> recordReading(ReadingHistory history) async {
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
  Future<ReadingHistory?> getByComicId(String comicId) async {
    final rust.ReadingHistoryDto? row = await guardFrb(
      () => rust.getReadingByComicIdFrb(comicId: comicId),
      fallbackMessage: '读取阅读进度失败',
    );
    return row == null ? null : mapReadingHistoryDto(row);
  }

  @override
  Stream<List<ReadingHistory>> watchAllHistory() {
    return guardFrbStream(
      () => rust.watchReadingHistoriesFrb().map(
        (List<rust.ReadingHistoryDto> rows) =>
            rows.map(mapReadingHistoryDto).toList(growable: false),
      ),
      fallbackMessage: '监听阅读历史失败',
    );
  }

  @override
  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  }) async {
    final String? normalizedKeyword = _normalizeKeyword(keyword);
    final rust.PagedReadingHistoryDto page = await guardFrb(
      () => rust.fetchReadingPageFrb(
        request: rust_comic.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
        keyword: normalizedKeyword,
      ),
      fallbackMessage: '读取阅读历史失败',
    );
    return mapPagedReadingHistory(page);
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
      logError(AppLog.dataRepo('reading_history'), '批量删除阅读历史失败', e, st);
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
