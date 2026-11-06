import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
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

class CatalogSelectionNotifier extends Notifier<CatalogSelectionState> {
  @override
  CatalogSelectionState build() {
    ref.listen(browseLibraryIdProvider, (_, _) {
      _reset();
    });
    ref.listen(libraryQueryIntentProvider.select((intent) => intent.keyword), (
      _,
      _,
    ) {
      _reset();
    });
    ref.listen(libraryComicFiltersProvider, (_, _) => _reset());
    ref.listen<bool>(libraryReorderActiveStateProvider, (_, bool active) {
      if (active) {
        exit();
      }
    });
    ref.listen(libraryDisplayTargetProvider, (_, LibraryDisplayTarget target) {
      if (target == LibraryDisplayTarget.series && state.active) {
        exit();
      }
    });
    return const CatalogSelectionState();
  }

  void enter([CatalogSelectionHost host = CatalogSelectionHost.libraryBrowse]) {
    ref.read(libraryReorderModePortProvider).exit();
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

void exitCatalogSelectionFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(context)
        .read(catalogSelectionProvider.notifier)
        .exit();
  } catch (_) {}
}
