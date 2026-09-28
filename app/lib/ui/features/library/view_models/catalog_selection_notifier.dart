import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_reorder_mode_notifier.dart';

class CatalogSelectionState {
  const CatalogSelectionState({
    this.active = false,
    this.selectedIds = const <String>{},
  });

  final bool active;
  final Set<String> selectedIds;

  int get count => selectedIds.length;

  CatalogSelectionState copyWith({bool? active, Set<String>? selectedIds}) {
    return CatalogSelectionState(
      active: active ?? this.active,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class CatalogSelectionNotifier extends Notifier<CatalogSelectionState> {
  @override
  CatalogSelectionState build() {
    ref.listen(
      currentLibraryProvider.select((s) => s.asData?.value.currentId),
      (_, __) {
        _reset();
      },
    );
    ref.listen(libraryQueryIntentProvider.select((intent) => intent.keyword), (
      _,
      __,
    ) {
      _reset();
    });
    ref.listen(libraryComicsTabSortOptionProvider, (_, __) => _reset());
    ref.listen(
      libraryComicsTabAgeRestrictionFilterProvider,
      (_, __) => _reset(),
    );
    ref.listen(libraryComicsTabMediaTypeFilterProvider, (_, __) => _reset());
    ref.listen(libraryComicsTabTagFilterProvider, (_, __) => _reset());
    ref.listen(libraryComicsTabAuthorFilterProvider, (_, __) => _reset());
    ref.listen(libraryComicsTabLanguageFilterProvider, (_, __) => _reset());
    ref.listen(libraryComicsTabParodyFilterProvider, (_, __) => _reset());
    ref.listen(libraryComicsTabCharacterFilterProvider, (_, __) => _reset());
    ref.listen(libraryComicsTabExpandBySeriesProvider, (_, __) => _reset());
    ref.listen(libraryDisplayTargetProvider, (_, LibraryDisplayTarget target) {
      if (target == LibraryDisplayTarget.series && state.active) {
        exit();
      }
    });
    return const CatalogSelectionState();
  }

  void enter() {
    ref.read(libraryReorderModeProvider.notifier).exit();
    state = state.copyWith(active: true);
  }

  void exit() {
    state = const CatalogSelectionState();
  }

  void toggle(String comicId) {
    if (!state.active) {
      return;
    }
    final Set<String> next = Set<String>.from(state.selectedIds);
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
    final Set<String> next = Set<String>.from(state.selectedIds)
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

  void _reset() {
    if (state.active || state.selectedIds.isNotEmpty) {
      state = const CatalogSelectionState();
    }
  }
}

final catalogSelectionProvider =
    NotifierProvider<CatalogSelectionNotifier, CatalogSelectionState>(
      CatalogSelectionNotifier.new,
    );

/// 离库页路由时退出选择模式；[ConsumerState.dispose] 中 [Ref] 已失效，须走 [ProviderScope]。
void exitCatalogSelectionFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(
      context,
    ).read(catalogSelectionProvider.notifier).exit();
  } catch (_) {}
}
