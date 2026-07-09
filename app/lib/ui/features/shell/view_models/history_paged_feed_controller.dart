import 'dart:async';

import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart'
    as entity;
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/debouncer.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_paged_feed_controller.g.dart';

const Duration _kHistoryKeywordDebounce = Duration(milliseconds: 300);
const Duration _kHistoryRefreshDebounce = Duration(milliseconds: 200);

@Riverpod(keepAlive: true)
Stream<List<entity.ReadingHistory>> readingHistoryChangesStream(Ref ref) {
  return ref.watch(readingHistoryRepoProvider).watchAllHistory();
}

@Riverpod(keepAlive: true)
class HistoryPagedFeedController extends _$HistoryPagedFeedController {
  static const int _pageSize = kDefaultPageSize;

  String _pendingKeyword = '';
  String _effectiveKeyword = '';
  Debouncer? _keywordDebounce;
  Debouncer? _refreshDebounce;
  bool _isRefreshing = false;
  bool _refreshPending = false;
  int _fetchGeneration = 0;
  StreamSubscription<List<entity.ReadingHistory>>? _historyChangesSubscription;

  @override
  Future<HistoryPagedFeedState> build() async {
    _keywordDebounce ??= Debouncer(duration: _kHistoryKeywordDebounce);
    _refreshDebounce ??= Debouncer(duration: _kHistoryRefreshDebounce);
    _historyChangesSubscription ??= ref
        .read(readingHistoryRepoProvider)
        .watchAllHistory()
        .listen((_) => _scheduleSilentRefresh());
    ref.onDispose(() {
      _keywordDebounce?.dispose();
      _refreshDebounce?.dispose();
      _historyChangesSubscription?.cancel();
      _historyChangesSubscription = null;
    });
    final HistoryPagedFeedState initial = await _loadPage(page: 1);
    if (_refreshPending) {
      _refreshPending = false;
      Future<void>.microtask(_silentRefresh);
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
      if (generation != _fetchGeneration) {
        return;
      }
      final HistoryPagedFeedState? latest = state.asData?.value;
      if (latest == null || latest.isLoadingMore != true) {
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
    } catch (_) {
      if (generation != _fetchGeneration) {
        return;
      }
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
    _keywordDebounce?.run(() {
      final String normalized = _pendingKeyword.trim();
      if (normalized == _effectiveKeyword) {
        return;
      }
      _effectiveKeyword = normalized;
      ref.invalidateSelf();
    });
  }

  void removeItem(String comicId) {
    final HistoryPagedFeedState? current = state.asData?.value;
    if (current == null) {
      return;
    }
    final List<HistoryGridItem> items = current.items
        .where((HistoryGridItem item) => item.comicId != comicId)
        .toList(growable: false);
    state = AsyncData<HistoryPagedFeedState>(
      current.copyWith(
        items: items,
        totalCount: (current.totalCount - 1).clamp(0, current.totalCount),
      ),
    );
  }

  void clearAllLocal() {
    state = AsyncData<HistoryPagedFeedState>(
      HistoryPagedFeedState(
        items: const <HistoryGridItem>[],
        totalCount: 0,
        loadedPage: 0,
        hasReachedEnd: true,
        keyword: _effectiveKeyword,
      ),
    );
  }

  void _scheduleSilentRefresh() {
    _refreshDebounce?.run(_silentRefresh);
  }

  Future<void> _silentRefresh() async {
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
      final HistoryPagedFeedState refreshed = await _loadPage(page: 1);
      if (generation != _fetchGeneration) {
        return;
      }
      state = AsyncData<HistoryPagedFeedState>(refreshed);
    } catch (error, stackTrace) {
      logError(AppLog.ui('history'), '静默刷新阅读历史失败', error, stackTrace);
    } finally {
      _isRefreshing = false;
      if (_refreshPending) {
        _refreshPending = false;
        _scheduleSilentRefresh();
      }
    }
  }

  Future<HistoryPagedFeedState> _loadPage({required int page}) async {
    final PagedResult<entity.ReadingHistory> result = await ref
        .read(readingHistoryRepoProvider)
        .fetchHistoryPage(
          pageRequest(page: page, pageSize: _pageSize),
          keyword: _keywordOrNull(),
        );
    return _stateFromPage(result, loadedPage: result.page);
  }

  String? _keywordOrNull() {
    return _effectiveKeyword.isEmpty ? null : _effectiveKeyword;
  }

  HistoryPagedFeedState _stateFromPage(
    PagedResult<entity.ReadingHistory> page, {
    required int loadedPage,
  }) {
    final List<HistoryGridItem> items = page.items
        .map(_mapHistoryItem)
        .toList(growable: false);
    return HistoryPagedFeedState(
      items: items,
      totalCount: page.totalCount,
      loadedPage: loadedPage,
      hasReachedEnd: !page.hasNextPage,
      keyword: _effectiveKeyword,
    );
  }

  HistoryPagedFeedState _mergePage({
    required HistoryPagedFeedState current,
    required PagedResult<entity.ReadingHistory> page,
    required int loadedPage,
  }) {
    final List<HistoryGridItem> appended = page.items
        .map(_mapHistoryItem)
        .toList(growable: false);
    final List<HistoryGridItem> items = <HistoryGridItem>[
      ...current.items,
      ...appended,
    ];
    return HistoryPagedFeedState(
      items: items,
      totalCount: page.totalCount,
      loadedPage: loadedPage,
      hasReachedEnd: !page.hasNextPage,
      keyword: _effectiveKeyword,
    );
  }

  HistoryGridItem _mapHistoryItem(entity.ReadingHistory history) {
    return historyGridItem(
      id: 'comic:${history.comicId}',
      title: history.title,
      lastReadTime: history.lastReadTime,
      coverComicId: history.comicId,
      comicId: history.comicId,
      pageIndex: history.pageIndex,
    );
  }
}
