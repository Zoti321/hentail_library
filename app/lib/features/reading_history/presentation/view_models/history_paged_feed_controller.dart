import 'dart:async';
import 'dart:math' as math;

import 'package:hentai_library/core/util/debouncer.dart';

import 'package:hentai_library/shared/application/logging/app_log.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_section_counts.dart';
import 'package:hentai_library/features/reading_history/public.dart' as entity;
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/features/reading_history/public/providers/reading_history_repository_providers.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_paged_feed_controller.g.dart';

const Duration _kHistoryKeywordDebounce = Duration(milliseconds: 300);
const Duration _kHistoryRefreshDebounce = Duration(milliseconds: 200);

@Riverpod()
class HistoryPagedFeedController extends _$HistoryPagedFeedController {
  static const int _pageSize = kDefaultPageSize;

  String _pendingKeyword = '';
  String _effectiveKeyword = '';
  Debouncer? _keywordDebounce;
  Debouncer? _refreshDebounce;
  bool _isRefreshing = false;
  bool _refreshPending = false;
  int _fetchGeneration = 0;
  int _queryGeneration = 0;
  StreamSubscription<void>? _historyChangesSubscription;

  @override
  Future<HistoryPagedFeedState> build() async {
    _queryGeneration++;
    final generation = ++_fetchGeneration;
    _isRefreshing = false;
    _refreshPending = false;
    _keywordDebounce ??= Debouncer(duration: _kHistoryKeywordDebounce);
    _refreshDebounce ??= Debouncer(duration: _kHistoryRefreshDebounce);
    _historyChangesSubscription ??= ref
        .read(readingHistoryRepoProvider)
        .watchHistoryChanges()
        .listen((_) => _scheduleSilentRefresh());
    ref.onDispose(() {
      _queryGeneration++;
      _fetchGeneration++;
      _keywordDebounce?.dispose();
      _refreshDebounce?.dispose();
      unawaited(_historyChangesSubscription?.cancel());
      _historyChangesSubscription = null;
    });
    final HistoryPagedFeedState initial = await _loadWindow(windowPages: 1);
    if (ref.mounted && generation == _fetchGeneration && _refreshPending) {
      _refreshPending = false;
      unawaited(Future<void>.microtask(_silentRefresh));
    }
    return initial;
  }

  Future<void> loadMore() async {
    final HistoryPagedFeedState? current = state.asData?.value;
    if (current == null ||
        current.isLoadingMore ||
        current.hasReachedEnd ||
        state.isLoading) {
      return;
    }

    final int generation = _fetchGeneration;
    state = AsyncData<HistoryPagedFeedState>(
      current.copyWith(isLoadingMore: true),
    );

    try {
      final int nextPage = current.loadedPage + 1;
      final PagedResult<entity.ReadingHistory> page = await ref
          .read(readingHistoryRepoProvider)
          .fetchHistoryPage(
            pageRequest(page: nextPage, pageSize: _pageSize),
            keyword: _keywordOrNull(),
          );
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      final HistoryPagedFeedState? latest = state.asData?.value;
      if (latest == null || !latest.isLoadingMore) {
        return;
      }
      final HistoryPagedFeedState merged = _mergePage(
        current: current,
        page: page,
        loadedPage: nextPage,
      );
      state = AsyncData<HistoryPagedFeedState>(
        merged.copyWith(isLoadingMore: false),
      );
    } catch (error, stackTrace) {
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      logError(AppLog.ui('history'), '加载更多阅读历史失败', error, stackTrace);
      final HistoryPagedFeedState? latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData<HistoryPagedFeedState>(
          latest.copyWith(isLoadingMore: false),
        );
      }
    }
  }

  void setKeyword(String value) {
    _pendingKeyword = value;
    final String normalized = value.trim();
    // 清空立即生效（clear 按钮不经 debounce）；输入仍防抖。
    if (normalized.isEmpty) {
      _keywordDebounce?.cancel();
      if (_effectiveKeyword.isEmpty) {
        return;
      }
      _effectiveKeyword = '';
      ref.invalidateSelf();
      return;
    }
    _keywordDebounce?.run(() {
      final String next = _pendingKeyword.trim();
      if (next == _effectiveKeyword) {
        return;
      }
      _effectiveKeyword = next;
      ref.invalidateSelf();
    });
  }

  /// 删除单本漫画的阅读历史；失败时抛出，本地列表保持不变。
  Future<void> deleteHistory(String comicId) async {
    final queryGeneration = _queryGeneration;
    await ref.read(readingHistoryRepoProvider).deleteByComicId(comicId);
    if (!_finishHistoryWrite(queryGeneration)) {
      return;
    }
    _removeItem(comicId);
  }

  /// 清空全部阅读历史；失败时抛出，本地列表保持不变。
  Future<void> clearAllHistory() async {
    final queryGeneration = _queryGeneration;
    await ref.read(readingHistoryRepoProvider).clearAllHistory();
    if (!_finishHistoryWrite(queryGeneration)) {
      return;
    }
    _clearAllLocal();
  }

  bool _finishHistoryWrite(int queryGeneration) {
    if (!ref.mounted || queryGeneration != _queryGeneration) {
      return false;
    }
    if (state.isLoading) {
      ref.invalidateSelf();
      return false;
    }
    _fetchGeneration++;
    _isRefreshing = false;
    if (_refreshPending) {
      _refreshPending = false;
      _scheduleSilentRefresh();
    }
    return true;
  }

  void _removeItem(String comicId) {
    final HistoryPagedFeedState? current = state.asData?.value;
    if (current == null) {
      return;
    }
    HistoryCardItem? removed;
    final List<HistoryCardItem> items = <HistoryCardItem>[];
    for (final HistoryCardItem item in current.items) {
      if (item.comicId == comicId) {
        removed = item;
      } else {
        items.add(item);
      }
    }
    if (removed == null) {
      state = AsyncData<HistoryPagedFeedState>(
        current.copyWith(isLoadingMore: false),
      );
      return;
    }
    final HistoryTimeSection section = historyTimeSectionFor(
      removed.lastReadTime,
      DateTime.now(),
    );
    state = AsyncData<HistoryPagedFeedState>(
      current.copyWith(
        items: items,
        totalCount: (current.totalCount - 1).clamp(0, current.totalCount),
        sectionCounts: decrementSectionCount(current.sectionCounts, section),
        isLoadingMore: false,
      ),
    );
  }

  void _clearAllLocal() {
    state = AsyncData<HistoryPagedFeedState>(
      HistoryPagedFeedState(
        items: const <HistoryCardItem>[],
        totalCount: 0,
        sectionCounts: ReadingHistorySectionCounts.zero,
        loadedPage: 0,
        hasReachedEnd: true,
        keyword: _effectiveKeyword,
      ),
    );
  }

  void _scheduleSilentRefresh() {
    if (ref.mounted) {
      _refreshDebounce?.run(_silentRefresh);
    }
  }

  Future<void> _silentRefresh() async {
    if (!ref.mounted) {
      return;
    }
    final HistoryPagedFeedState? current = state.asData?.value;
    if (current == null) {
      _refreshPending = true;
      return;
    }
    if (_isRefreshing) {
      _refreshPending = true;
      return;
    }

    _fetchGeneration++;
    final int generation = _fetchGeneration;
    _isRefreshing = true;

    try {
      final int windowPages = math.max(1, current.loadedPage);
      final HistoryPagedFeedState refreshed = await _loadWindow(
        windowPages: windowPages,
      );
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      state = AsyncData<HistoryPagedFeedState>(refreshed);
    } catch (error, stackTrace) {
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      logError(AppLog.ui('history'), '静默刷新阅读历史失败', error, stackTrace);
    } finally {
      if (ref.mounted && generation == _fetchGeneration) {
        _isRefreshing = false;
        if (_refreshPending) {
          _refreshPending = false;
          _scheduleSilentRefresh();
        }
      }
    }
  }

  Future<HistoryPagedFeedState> _loadWindow({required int windowPages}) async {
    final String keyword = _effectiveKeyword;
    final int pageSize = math.max(1, windowPages) * _pageSize;
    final Future<PagedResult<entity.ReadingHistory>> pageFuture = ref
        .read(readingHistoryRepoProvider)
        .fetchHistoryPage(
          pageRequest(page: 1, pageSize: pageSize),
          keyword: keyword.isEmpty ? null : keyword,
        );
    final Future<ReadingHistorySectionCounts> countsFuture = ref
        .read(readingHistoryRepoProvider)
        .fetchSectionCounts(keyword: keyword.isEmpty ? null : keyword);
    final List<Object> results = await Future.wait<Object>(
      <Future<Object>>[pageFuture, countsFuture],
    );
    final PagedResult<entity.ReadingHistory> page =
        results[0] as PagedResult<entity.ReadingHistory>;
    final ReadingHistorySectionCounts sectionCounts =
        results[1] as ReadingHistorySectionCounts;
    return _stateFromPage(
      page,
      sectionCounts: sectionCounts,
      requestedWindowPages: windowPages,
      keyword: keyword,
    );
  }

  String? _keywordOrNull() {
    return _effectiveKeyword.isEmpty ? null : _effectiveKeyword;
  }

  HistoryPagedFeedState _stateFromPage(
    PagedResult<entity.ReadingHistory> page, {
    required ReadingHistorySectionCounts sectionCounts,
    required int requestedWindowPages,
    required String keyword,
  }) {
    final List<HistoryCardItem> items = page.items
        .map(_mapHistoryItem)
        .toList(growable: false);
    if (page.totalCount <= 0) {
      return HistoryPagedFeedState(
        items: const <HistoryCardItem>[],
        totalCount: 0,
        sectionCounts: sectionCounts,
        loadedPage: 0,
        hasReachedEnd: true,
        keyword: keyword,
      );
    }
    // First page: trust result page metadata (same as pre-window refresh).
    if (requestedWindowPages <= 1) {
      return HistoryPagedFeedState(
        items: items,
        totalCount: page.totalCount,
        sectionCounts: sectionCounts,
        loadedPage: page.page,
        hasReachedEnd: !page.hasNextPage,
        keyword: keyword,
      );
    }
    // Silent-refresh window: keep scroll depth; end when the window covers total.
    final int maxPage = math.max(
      1,
      (page.totalCount + _pageSize - 1) ~/ _pageSize,
    );
    return HistoryPagedFeedState(
      items: items,
      totalCount: page.totalCount,
      sectionCounts: sectionCounts,
      loadedPage: math.min(requestedWindowPages, maxPage),
      hasReachedEnd: items.length >= page.totalCount,
      keyword: keyword,
    );
  }

  HistoryPagedFeedState _mergePage({
    required HistoryPagedFeedState current,
    required PagedResult<entity.ReadingHistory> page,
    required int loadedPage,
  }) {
    final List<HistoryCardItem> appended = page.items
        .map(_mapHistoryItem)
        .toList(growable: false);
    final List<HistoryCardItem> items = <HistoryCardItem>[
      ...current.items,
      ...appended,
    ];
    return HistoryPagedFeedState(
      items: items,
      totalCount: page.totalCount,
      sectionCounts: current.sectionCounts,
      loadedPage: loadedPage,
      hasReachedEnd: !page.hasNextPage,
      keyword: current.keyword,
    );
  }

  HistoryCardItem _mapHistoryItem(entity.ReadingHistory history) {
    return historyCardItem(
      id: 'comic:${history.comicId}',
      title: history.title,
      lastReadTime: history.lastReadTime,
      coverComicId: history.comicId,
      comicId: history.comicId,
      pageIndex: history.pageIndex,
      pageCount: history.pageCount,
    );
  }
}
