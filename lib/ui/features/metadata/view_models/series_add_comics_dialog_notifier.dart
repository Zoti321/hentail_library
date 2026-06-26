import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/deps/repos.dart';

class SeriesAddComicsSubmitSummary {
  const SeriesAddComicsSubmitSummary({
    this.addedCount = 0,
    this.orderChanged = false,
    this.removedFromSeriesCount = 0,
  });

  final int addedCount;
  final bool orderChanged;

  /// 本次提交从系列中移出的本数（含清空全部与部分取消勾选）。
  final int removedFromSeriesCount;

  bool get hasAnyChange =>
      addedCount > 0 || orderChanged || removedFromSeriesCount > 0;
}

class SeriesAddComicsDialogState {
  const SeriesAddComicsDialogState({
    this.query = '',
    this.selectedComicIdsInOrder = const <String>[],
    this.submitting = false,
    this.visibleComics = const <Comic>[],
    this.existingComicIds = const <String>{},
    this.selectableComicIds = const <String>{},
  });

  final String query;
  final List<String> selectedComicIdsInOrder;
  final bool submitting;
  final List<Comic> visibleComics;
  final Set<String> existingComicIds;
  final Set<String> selectableComicIds;

  bool get canSubmit =>
      !submitting &&
      (selectedComicIdsInOrder.isNotEmpty || existingComicIds.isNotEmpty);

  SeriesAddComicsDialogState copyWith({
    String? query,
    List<String>? selectedComicIdsInOrder,
    bool? submitting,
    List<Comic>? visibleComics,
    Set<String>? existingComicIds,
    Set<String>? selectableComicIds,
  }) {
    return SeriesAddComicsDialogState(
      query: query ?? this.query,
      selectedComicIdsInOrder:
          selectedComicIdsInOrder ?? this.selectedComicIdsInOrder,
      submitting: submitting ?? this.submitting,
      visibleComics: visibleComics ?? this.visibleComics,
      existingComicIds: existingComicIds ?? this.existingComicIds,
      selectableComicIds: selectableComicIds ?? this.selectableComicIds,
    );
  }
}

class SeriesAddComicsDialogNotifier
    extends Notifier<SeriesAddComicsDialogState> {
  List<Comic> _allComics = const <Comic>[];
  Set<String> _existingComicIds = const <String>{};

  /// 系列内顺序（与 [SeriesItem.order] 一致），用于首次把已在系列的可见条目置为「选中」UI。
  List<String> _existingComicIdsInSeriesOrder = const <String>[];
  bool _needsSeedSelectedExisting = true;

  @override
  SeriesAddComicsDialogState build() => const SeriesAddComicsDialogState();

  void reset() {
    _needsSeedSelectedExisting = true;
    _allComics = const <Comic>[];
    _existingComicIds = const <String>{};
    _existingComicIdsInSeriesOrder = const <String>[];
    state = const SeriesAddComicsDialogState();
    _recomputeVisibleAndSelection();
  }

  void updateSource({
    required List<Comic> comics,
    required List<String> existingComicIdsInSeriesOrder,
  }) {
    final Set<String> existingSet = existingComicIdsInSeriesOrder.toSet();
    final sameComics = listEquals(
      _allComics.map((Comic e) => e.comicId).toList(),
      comics.map((Comic e) => e.comicId).toList(),
    );
    final sameExisting = listEquals(
      _existingComicIdsInSeriesOrder,
      existingComicIdsInSeriesOrder,
    );
    if (sameComics && sameExisting) return;
    if (!sameExisting) {
      _needsSeedSelectedExisting = true;
    }
    _allComics = comics;
    _existingComicIdsInSeriesOrder = List<String>.from(
      existingComicIdsInSeriesOrder,
    );
    _existingComicIds = existingSet;
    _recomputeVisibleAndSelection();
  }

  void setQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == state.query) return;
    state = state.copyWith(query: trimmed);
    _recomputeVisibleAndSelection();
  }

  void toggleSelected(String comicId) {
    if (state.submitting || !state.selectableComicIds.contains(comicId)) {
      return;
    }
    final next = List<String>.from(state.selectedComicIdsInOrder);
    final idx = next.indexOf(comicId);
    if (idx >= 0) {
      next.removeAt(idx);
    } else {
      next.add(comicId);
    }
    state = state.copyWith(selectedComicIdsInOrder: next);
  }

  Future<SeriesAddComicsSubmitSummary?> submit({
    required String seriesName,
    required List<SeriesItem> existingItems,
  }) async {
    if (!state.canSubmit) return null;
    final sorted = List<SeriesItem>.from(existingItems)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final List<String> e = sorted.map((SeriesItem it) => it.comicId).toList();
    final List<String> sel = List<String>.from(state.selectedComicIdsInOrder);
    if (sel.isEmpty) {
      if (e.isEmpty) {
        return const SeriesAddComicsSubmitSummary();
      }
      state = state.copyWith(submitting: true);
      try {
        final repo = ref.read(librarySeriesRepoProvider);
        await repo.removeComicsFromSeries(e);
        ref.invalidate(allSeriesProvider);
        state = state.copyWith(
          submitting: false,
          selectedComicIdsInOrder: const <String>[],
          query: '',
        );
        _recomputeVisibleAndSelection();
        return SeriesAddComicsSubmitSummary(removedFromSeriesCount: e.length);
      } catch (_) {
        state = state.copyWith(submitting: false);
        rethrow;
      }
    }
    final Set<String> selSet = sel.toSet();
    final Set<String> eSet = e.toSet();
    final List<String> toRemove = e
        .where((String id) => !selSet.contains(id))
        .toList();
    final List<String> toAdd = <String>[];
    final Set<String> seenAdd = <String>{};
    for (final String id in sel) {
      if (!eSet.contains(id) && seenAdd.add(id)) {
        toAdd.add(id);
      }
    }
    final Set<String> toAddSet = toAdd.toSet();
    final List<String> eKept = e
        .where((String id) => selSet.contains(id))
        .toList();
    final List<String> selKept = sel
        .where((String id) => eSet.contains(id))
        .toList();
    final bool orderChanged = !listEquals(eKept, selKept);
    final int addedCount = toAdd.length;
    final int removedCount = toRemove.length;
    final bool hasAnyChange =
        removedCount > 0 || addedCount > 0 || orderChanged;
    if (!hasAnyChange) {
      return const SeriesAddComicsSubmitSummary();
    }
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(librarySeriesRepoProvider);
      if (toRemove.isNotEmpty) {
        await repo.removeComicsFromSeries(toRemove);
      }
      for (int i = 0; i < sel.length; i++) {
        final String id = sel[i];
        if (toAddSet.contains(id)) {
          await repo.assignComicExclusive(
            comicId: id,
            targetSeriesName: seriesName,
            order: i,
          );
        }
      }
      await repo.setSeriesItemsOrder(
        seriesName,
        sel
            .asMap()
            .entries
            .map(
              (MapEntry<int, String> entry) =>
                  SeriesItem(comicId: entry.value, order: entry.key),
            )
            .toList(),
      );
      ref.invalidate(allSeriesProvider);
      state = state.copyWith(
        submitting: false,
        selectedComicIdsInOrder: const <String>[],
        query: '',
      );
      _recomputeVisibleAndSelection();
      return SeriesAddComicsSubmitSummary(
        addedCount: addedCount,
        orderChanged: orderChanged,
        removedFromSeriesCount: removedCount,
      );
    } catch (_) {
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }

  List<Comic> _orderVisibleWithExistingSeriesFirst(List<Comic> visible) {
    if (visible.isEmpty || _existingComicIdsInSeriesOrder.isEmpty) {
      return visible;
    }
    final Map<String, Comic> byId = <String, Comic>{
      for (final Comic c in visible) c.comicId: c,
    };
    final List<Comic> result = <Comic>[];
    final Set<String> placed = <String>{};
    for (final String id in _existingComicIdsInSeriesOrder) {
      final Comic? c = byId[id];
      if (c != null) {
        result.add(c);
        placed.add(id);
      }
    }
    for (final Comic c in visible) {
      if (!placed.contains(c.comicId)) {
        result.add(c);
      }
    }
    return result;
  }

  void _recomputeVisibleAndSelection() {
    final String q = state.query.toLowerCase();
    final List<Comic> visible = _orderVisibleWithExistingSeriesFirst(
      _allComics.where((Comic comic) {
        if (q.isEmpty) return true;
        final String title = comic.title.toLowerCase();
        final String author = comic.authors
            .map((a) => a.name)
            .join(' ')
            .toLowerCase();
        return title.contains(q) || author.contains(q);
      }).toList(),
    );
    final Set<String> visibleIds = visible.map((Comic e) => e.comicId).toSet();
    final Set<String> allComicIds = _allComics
        .map((Comic e) => e.comicId)
        .toSet();
    final Set<String> selectable = visibleIds;
    List<String> keepSelected = state.selectedComicIdsInOrder
        .where((String id) => allComicIds.contains(id))
        .toList();
    if (_needsSeedSelectedExisting && visible.isNotEmpty) {
      _needsSeedSelectedExisting = false;
      keepSelected = _existingComicIdsInSeriesOrder
          .where((String id) => allComicIds.contains(id))
          .toList();
    }
    final SeriesAddComicsDialogState next = state.copyWith(
      visibleComics: visible,
      existingComicIds: _existingComicIds,
      selectableComicIds: selectable,
      selectedComicIdsInOrder: keepSelected,
    );
    final bool unchanged =
        listEquals(
          state.visibleComics.map((Comic e) => e.comicId).toList(),
          next.visibleComics.map((Comic e) => e.comicId).toList(),
        ) &&
        setEquals(state.existingComicIds, next.existingComicIds) &&
        setEquals(state.selectableComicIds, next.selectableComicIds) &&
        listEquals(state.selectedComicIdsInOrder, next.selectedComicIdsInOrder);
    if (!unchanged) {
      state = next;
    }
  }
}

final seriesAddComicsDialogProvider =
    NotifierProvider<SeriesAddComicsDialogNotifier, SeriesAddComicsDialogState>(
      SeriesAddComicsDialogNotifier.new,
    );
