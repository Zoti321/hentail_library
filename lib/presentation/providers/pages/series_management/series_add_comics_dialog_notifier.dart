import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/pages/series_management/series_management_notifier.dart';
import 'package:hentai_library/presentation/providers/usecases/comic_meta.dart';

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

  bool get canSubmit => !submitting && selectedComicIdsInOrder.isNotEmpty;

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

class SeriesAddComicsDialogNotifier extends Notifier<SeriesAddComicsDialogState> {
  List<Comic> _allComics = const <Comic>[];
  Set<String> _existingComicIds = const <String>{};

  @override
  SeriesAddComicsDialogState build() => const SeriesAddComicsDialogState();

  /// Clears search [SeriesAddComicsDialogState.query], selection, and submitting;
  /// recomputes [SeriesAddComicsDialogState.visibleComics] from [_allComics].
  /// Call when opening or closing the add-comics dialog so global state does not leak.
  void reset() {
    state = const SeriesAddComicsDialogState();
    _recomputeVisibleAndSelection();
  }

  void updateSource({
    required List<Comic> comics,
    required Set<String> existingComicIds,
  }) {
    final sameComics = listEquals(
      _allComics.map((e) => e.comicId).toList(),
      comics.map((e) => e.comicId).toList(),
    );
    final sameExisting = setEquals(_existingComicIds, existingComicIds);
    if (sameComics && sameExisting) return;
    _allComics = comics;
    _existingComicIds = existingComicIds;
    _recomputeVisibleAndSelection();
  }

  void setQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == state.query) return;
    state = state.copyWith(query: trimmed);
    _recomputeVisibleAndSelection();
  }

  void toggleSelected(String comicId) {
    if (state.submitting || !state.selectableComicIds.contains(comicId)) return;
    final next = List<String>.from(state.selectedComicIdsInOrder);
    final idx = next.indexOf(comicId);
    if (idx >= 0) {
      next.removeAt(idx);
    } else {
      next.add(comicId);
    }
    state = state.copyWith(selectedComicIdsInOrder: next);
  }

  Future<int> submit({
    required String seriesName,
    required List<int> existingOrders,
  }) async {
    if (!state.canSubmit) return 0;
    state = state.copyWith(submitting: true);
    final selected = List<String>.from(state.selectedComicIdsInOrder);
    var nextOrder = existingOrders.isEmpty
        ? 0
        : existingOrders.reduce(max) + 1;

    try {
      final assign = ref.read(assignLibraryComicToSeriesUseCaseProvider);
      for (final comicId in selected) {
        await assign.call(
          comicId: comicId,
          targetSeriesName: seriesName,
          order: nextOrder,
        );
        nextOrder += 1;
      }
      ref.invalidate(allSeriesProvider);
      state = state.copyWith(
        submitting: false,
        selectedComicIdsInOrder: const <String>[],
        query: '',
      );
      _recomputeVisibleAndSelection();
      return selected.length;
    } catch (_) {
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }

  void _recomputeVisibleAndSelection() {
    final q = state.query.toLowerCase();
    final visible = _allComics.where((comic) {
      if (q.isEmpty) return true;
      final title = comic.title.toLowerCase();
      final author = comic.authors.join(' ').toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();

    final visibleIds = visible.map((e) => e.comicId).toSet();
    final selectable = visible
        .where((comic) => !_existingComicIds.contains(comic.comicId))
        .map((comic) => comic.comicId)
        .toSet();
    final keepSelected = state.selectedComicIdsInOrder
        .where((id) => !_existingComicIds.contains(id) && visibleIds.contains(id))
        .toList();

    final next = state.copyWith(
      visibleComics: visible,
      existingComicIds: _existingComicIds,
      selectableComicIds: selectable,
      selectedComicIdsInOrder: keepSelected,
    );
    final unchanged =
        listEquals(
          state.visibleComics.map((e) => e.comicId).toList(),
          next.visibleComics.map((e) => e.comicId).toList(),
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
