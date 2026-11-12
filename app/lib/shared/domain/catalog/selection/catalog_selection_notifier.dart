import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hentai_library/shared/di/library_state_providers.dart';

/// 多选模式宿主：同一 [catalogSelectionProvider] 按页面隔离 UI。
enum CatalogSelectionHost { libraryBrowse, seriesDetail }

class CatalogSelectionState {
  const CatalogSelectionState({
    this.active = false,
    this.host,
    this.selectedIds = const <String>{},
  });

  final bool active;
  final CatalogSelectionHost? host;
  final Set<String> selectedIds;

  int get count => selectedIds.length;

  bool get isLibraryBrowseSelection =>
      active && host == CatalogSelectionHost.libraryBrowse;

  bool get isSeriesDetailSelection =>
      active && host == CatalogSelectionHost.seriesDetail;

  CatalogSelectionState copyWith({
    bool? active,
    CatalogSelectionHost? host,
    Set<String>? selectedIds,
    bool clearHost = false,
  }) {
    return CatalogSelectionState(
      active: active ?? this.active,
      host: clearHost ? null : (host ?? this.host),
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

/// 跨模块多选状态（壳与 owner 详情共用）；查询/筛选联动由壳自行 [reset]。
class CatalogSelectionNotifier extends Notifier<CatalogSelectionState> {
  @override
  CatalogSelectionState build() {
    ref.listen<bool>(libraryReorderActiveStateProvider, (
      bool? previous,
      bool next,
    ) {
      if (next) {
        exit();
      }
    });
    return const CatalogSelectionState();
  }

  void enter([CatalogSelectionHost host = CatalogSelectionHost.libraryBrowse]) {
    ref.read(exitLibraryReorderCommandProvider)();
    state = CatalogSelectionState(
      active: true,
      host: host,
      selectedIds: const <String>{},
    );
  }

  void exit() {
    state = const CatalogSelectionState();
  }

  void toggle(String comicId) {
    if (!state.active) {
      return;
    }
    final Set<String> next = Set<String>.of(state.selectedIds);
    if (next.contains(comicId)) {
      next.remove(comicId);
    } else {
      next.add(comicId);
    }
    state = state.copyWith(selectedIds: next);
  }

  void selectPage(Iterable<String> comicIds) {
    if (!state.active) {
      return;
    }
    final Set<String> next = Set<String>.of(state.selectedIds)
      ..addAll(comicIds);
    state = state.copyWith(selectedIds: next);
  }

  void clearSelection() {
    if (state.selectedIds.isEmpty) {
      return;
    }
    state = state.copyWith(selectedIds: const <String>{});
  }

  bool isSelected(String comicId) => state.selectedIds.contains(comicId);

  /// 查询/筛选/库上下文变化时由壳调用。
  void reset() {
    if (state.active || state.selectedIds.isNotEmpty) {
      state = const CatalogSelectionState();
    }
  }
}

final catalogSelectionProvider =
    NotifierProvider<CatalogSelectionNotifier, CatalogSelectionState>(
      CatalogSelectionNotifier.new,
    );

void exitCatalogSelectionFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(context)
        .read(catalogSelectionProvider.notifier)
        .exit();
  } catch (_) {}
}
