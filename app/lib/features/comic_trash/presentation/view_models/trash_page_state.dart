import 'package:hentai_library/features/comic_trash/domain/comic_purge_policy.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';

/// 「已删除」页状态：分页列表 + 多选。
class TrashPageState {
  const TrashPageState({
    this.items = const <TrashedComic>[],
    this.totalCount = 0,
    this.counts = (total: 0, local: 0, remote: 0),
    this.loadedPage = 0,
    this.hasReachedEnd = true,
    this.isLoadingMore = false,
    this.selectionMode = true,
    this.selectedIds = const <String>{},
  });

  final List<TrashedComic> items;
  final int totalCount;

  /// 全部 trash 的 Local / Remote 计数（「全部永久删除」确认文案用）。
  final TrashedComicCounts counts;
  final int loadedPage;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final bool selectionMode;
  final Set<String> selectedIds;

  bool get isEmpty => items.isEmpty;

  List<TrashedComic> get selectedItems => items
      .where((TrashedComic item) => selectedIds.contains(item.comic.comicId))
      .toList(growable: false);

  bool get allLoadedSelected =>
      items.isNotEmpty && selectedIds.length == items.length;

  PurgeTargetCounts get selectedPurgeCounts => countPurgeTargets(selectedItems);

  PurgeTargetCounts get allPurgeCounts =>
      (local: counts.local, remote: counts.remote);

  TrashPageState enterSelection() =>
      copyWith(selectionMode: true, selectedIds: const <String>{});

  TrashPageState exitSelection() =>
      copyWith(selectionMode: false, selectedIds: const <String>{});

  TrashPageState clearSelection() =>
      copyWith(selectionMode: true, selectedIds: const <String>{});

  TrashPageState toggleSelected(String comicId) {
    final Set<String> next = <String>{...selectedIds};
    if (!next.remove(comicId)) {
      next.add(comicId);
    }
    return copyWith(selectionMode: true, selectedIds: next);
  }

  /// 已全选时再次调用则清空选择。
  TrashPageState toggleSelectAllLoaded() {
    if (allLoadedSelected) {
      return copyWith(selectedIds: const <String>{});
    }
    return copyWith(
      selectionMode: true,
      selectedIds: items.map((TrashedComic item) => item.comic.comicId).toSet(),
    );
  }

  /// 列表刷新后丢弃已不在列表中的选择。
  TrashPageState withItems({
    required List<TrashedComic> items,
    required int totalCount,
    required TrashedComicCounts counts,
    required int loadedPage,
    required bool hasReachedEnd,
  }) {
    final Set<String> visibleIds = items
        .map((TrashedComic item) => item.comic.comicId)
        .toSet();
    return copyWith(
      items: items,
      totalCount: totalCount,
      counts: counts,
      loadedPage: loadedPage,
      hasReachedEnd: hasReachedEnd,
      isLoadingMore: false,
      selectedIds: selectedIds.intersection(visibleIds),
    );
  }

  TrashPageState copyWith({
    List<TrashedComic>? items,
    int? totalCount,
    TrashedComicCounts? counts,
    int? loadedPage,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    bool? selectionMode,
    Set<String>? selectedIds,
  }) {
    return TrashPageState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      counts: counts ?? this.counts,
      loadedPage: loadedPage ?? this.loadedPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}
