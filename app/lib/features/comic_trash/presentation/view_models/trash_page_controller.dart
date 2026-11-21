import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/logging/app_log.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/comic_trash/presentation/providers/comic_trash_use_case_provider.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/comic_trash_actions.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/library_admin/public.dart';

part 'trash_page_controller.g.dart';

/// 回收站页 ViewModel：分页加载、多选、恢复 / 永久删除。
@riverpod
class TrashPageController extends _$TrashPageController {
  static const int _pageSize = kDefaultPageSize;

  int _fetchGeneration = 0;
  int _selectionGeneration = 0;
  int? _activeRefreshGeneration;

  @override
  Future<TrashPageState> build() async {
    _fetchGeneration++;
    _activeRefreshGeneration = null;
    _selectionGeneration++;
    ref.onDispose(() {
      _fetchGeneration++;
      _selectionGeneration++;
      _activeRefreshGeneration = null;
    });
    ref.listen(
      libraryRevisionStateProvider.select(
        (LibraryRevisionState s) => s.revision,
      ),
      (int? _, int _) => refresh(),
    );
    return _reload(const TrashPageState());
  }

  /// 保留多选状态重新加载已加载过的所有页。
  Future<void> refresh() async {
    final TrashPageState? current = state.asData?.value;
    if (current == null) {
      return;
    }
    final int generation = ++_fetchGeneration;
    _activeRefreshGeneration = generation;
    if (current.isLoadingMore) {
      state = AsyncData<TrashPageState>(current.copyWith(isLoadingMore: false));
    }
    try {
      final TrashPageState next = await _reload(current);
      if (ref.mounted && generation == _fetchGeneration) {
        final latest = state.asData?.value;
        if (latest != null) {
          state = AsyncData<TrashPageState>(
            latest.withItems(
              items: next.items,
              totalCount: next.totalCount,
              counts: next.counts,
              loadedPage: next.loadedPage,
              hasReachedEnd: next.hasReachedEnd,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      logError(AppLog.ui('trash'), '刷新已删除漫画失败', error, stackTrace);
    } finally {
      if (_activeRefreshGeneration == generation) {
        _activeRefreshGeneration = null;
      }
    }
  }

  Future<void> loadMore() async {
    final TrashPageState? current = state.asData?.value;
    if (current == null ||
        current.isLoadingMore ||
        current.hasReachedEnd ||
        state.isLoading ||
        _activeRefreshGeneration != null) {
      return;
    }
    final int generation = _fetchGeneration;
    state = AsyncData<TrashPageState>(current.copyWith(isLoadingMore: true));
    try {
      final int nextPage = current.loadedPage + 1;
      final PagedResult<TrashedComic> page = await ref
          .read(comicTrashServiceProvider)
          .fetchTrashedPage(pageRequest(page: nextPage, pageSize: _pageSize));
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      final TrashPageState latest = state.asData?.value ?? current;
      state = AsyncData<TrashPageState>(
        latest.withItems(
          items: <TrashedComic>[...latest.items, ...page.items],
          totalCount: page.totalCount,
          counts: latest.counts,
          loadedPage: nextPage,
          hasReachedEnd: !page.hasNextPage,
        ),
      );
    } catch (error, stackTrace) {
      if (!ref.mounted || generation != _fetchGeneration) {
        return;
      }
      logError(AppLog.ui('trash'), '加载更多已删除漫画失败', error, stackTrace);
      final TrashPageState? latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData<TrashPageState>(
          latest.copyWith(isLoadingMore: false),
        );
      }
    }
  }

  void enterSelection() =>
      _editSelection((TrashPageState s) => s.enterSelection());

  void exitSelection() =>
      _editSelection((TrashPageState s) => s.exitSelection());

  void toggleSelected(String comicId) =>
      _editSelection((TrashPageState s) => s.toggleSelected(comicId));

  void toggleSelectAllLoaded() =>
      _editSelection((TrashPageState s) => s.toggleSelectAllLoaded());

  /// 恢复给定漫画并退出多选；列表随 library revision 刷新。返回恢复数量。
  Future<int> restore(List<String> comicIds) async {
    final generation = _selectionGeneration;
    await ref.read(comicTrashActionsProvider.notifier).restore(comicIds);
    _clearCompletedSelection(generation);
    return comicIds.length;
  }

  Future<int> restoreAll() async {
    final generation = _selectionGeneration;
    final int restored = await ref
        .read(comicTrashActionsProvider.notifier)
        .restoreAll();
    _clearCompletedSelection(generation);
    return restored;
  }

  Future<ComicPurgeResult> purge(List<String> comicIds) async {
    final generation = _selectionGeneration;
    final ComicPurgeResult result = await ref
        .read(comicTrashActionsProvider.notifier)
        .purge(comicIds);
    _clearCompletedSelection(generation);
    return result;
  }

  Future<ComicPurgeResult> purgeAll() async {
    final generation = _selectionGeneration;
    final ComicPurgeResult result = await ref
        .read(comicTrashActionsProvider.notifier)
        .purgeAll();
    _clearCompletedSelection(generation);
    return result;
  }

  void _editSelection(TrashPageState Function(TrashPageState) transform) {
    _selectionGeneration++;
    _update(transform);
  }

  void _clearCompletedSelection(int generation) {
    if (generation == _selectionGeneration) {
      _update((TrashPageState s) => s.clearSelection());
    }
  }

  void _update(TrashPageState Function(TrashPageState) transform) {
    if (!ref.mounted) {
      return;
    }
    final TrashPageState? current = state.asData?.value;
    if (current != null) {
      state = AsyncData<TrashPageState>(transform(current));
    }
  }

  Future<TrashPageState> _reload(TrashPageState base) async {
    final int pageSize =
        _pageSize * (base.loadedPage < 1 ? 1 : base.loadedPage);
    final service = ref.read(comicTrashServiceProvider);
    final PagedResult<TrashedComic> page = await service.fetchTrashedPage(
      pageRequest(page: 1, pageSize: pageSize),
    );
    final TrashedComicCounts counts = await service.countTrashed();
    final int loadedPage = page.items.isEmpty
        ? 0
        : (page.items.length + _pageSize - 1) ~/ _pageSize;
    return base.withItems(
      items: page.items,
      totalCount: page.totalCount,
      counts: counts,
      loadedPage: loadedPage,
      hasReachedEnd: !page.hasNextPage,
    );
  }
}
