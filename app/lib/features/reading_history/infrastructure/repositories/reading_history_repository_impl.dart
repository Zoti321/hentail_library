import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/features/reading_history/infrastructure/mappers/history_frb_mapper.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_search_specification.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust_comic;
import 'package:hentai_library/src/rust/api/history.dart' as rust;

class ReadingHistoryRepositoryImpl implements ReadingHistoryRepository {
  const ReadingHistoryRepositoryImpl();

  @override
  Future<void> recordReading(ReadingHistory history) async {
    try {
      await guardFrb(
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
      Error.throwWithStackTrace(
        AppException('记录阅读进度失败', cause: e, stackTrace: st),
        st,
      );
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
  Stream<void> watchHistoryChanges() {
    return guardFrbStream(
      () => rust.watchReadingHistoryChangesFrb().map((int _) {}),
      fallbackMessage: '监听阅读历史变更失败',
    );
  }

  @override
  Future<Map<String, int>> listReadPageIndexes() async {
    final List<rust.ReadPageIndexDto> rows = await guardFrb(
      rust.listReadPageIndexesFrb,
      fallbackMessage: '读取阅读进度索引失败',
    );
    return <String, int>{
      for (final rust.ReadPageIndexDto row in rows) row.comicId: row.pageIndex,
    };
  }

  @override
  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  }) async {
    final String? normalizedKeyword =
        ReadingHistorySearchSpecification.normalizeKeyword(keyword);
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
      Error.throwWithStackTrace(
        AppException('删除阅读历史失败', cause: e, stackTrace: st),
        st,
      );
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
      Error.throwWithStackTrace(
        AppException('批量删除阅读历史失败', cause: e, stackTrace: st),
        st,
      );
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
      Error.throwWithStackTrace(
        AppException('清空阅读历史失败', cause: e, stackTrace: st),
        st,
      );
    }
  }
}
