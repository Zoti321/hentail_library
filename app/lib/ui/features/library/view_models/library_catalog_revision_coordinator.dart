import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_revision_coordinator.g.dart';

const Duration kLibraryInactiveCatalogRefreshDebounce = Duration(seconds: 3);

@immutable
class LibraryCatalogRevisionSnapshot {
  const LibraryCatalogRevisionSnapshot({
    required this.activeRevision,
    required this.inactiveRevision,
  });

  final int activeRevision;
  final int inactiveRevision;

  LibraryCatalogRevisionSnapshot copyWith({
    int? activeRevision,
    int? inactiveRevision,
  }) {
    return LibraryCatalogRevisionSnapshot(
      activeRevision: activeRevision ?? this.activeRevision,
      inactiveRevision: inactiveRevision ?? this.inactiveRevision,
    );
  }
}

/// Sync 后：活跃 Tab 立即刷新 catalog；非活跃 Tab debounce 后再刷新。
@Riverpod(keepAlive: true)
class LibraryCatalogRevisionCoordinator
    extends _$LibraryCatalogRevisionCoordinator {
  Timer? _inactiveRefreshTimer;

  @override
  LibraryCatalogRevisionSnapshot build() {
    ref.onDispose(() {
      _inactiveRefreshTimer?.cancel();
    });

    ref.listen(libraryRevisionProvider, (
      LibraryRevisionState? previous,
      LibraryRevisionState next,
    ) {
      if (previous?.revision == next.revision) {
        return;
      }
      _onRevisionBumped(next.revision);
    });

    ref.listen(libraryDisplayTargetProvider, (
      LibraryDisplayTarget? previous,
      LibraryDisplayTarget next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _flushInactiveRevisionOnTabSwitch();
    });

    return const LibraryCatalogRevisionSnapshot(
      activeRevision: 0,
      inactiveRevision: 0,
    );
  }

  void _onRevisionBumped(int revision) {
    _inactiveRefreshTimer?.cancel();
    state = state.copyWith(activeRevision: revision);
    _inactiveRefreshTimer = Timer(kLibraryInactiveCatalogRefreshDebounce, () {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(inactiveRevision: revision);
    });
  }

  void _flushInactiveRevisionOnTabSwitch() {
    _inactiveRefreshTimer?.cancel();
    _inactiveRefreshTimer = null;
    if (state.inactiveRevision == state.activeRevision) {
      return;
    }
    state = state.copyWith(inactiveRevision: state.activeRevision);
  }
}

/// 指定 Tab 应监听的 catalog revision 计数。
@riverpod
int libraryCatalogWatchRevision(Ref ref, LibraryDisplayTarget target) {
  final LibraryCatalogRevisionSnapshot snapshot = ref.watch(
    libraryCatalogRevisionCoordinatorProvider,
  );
  final LibraryDisplayTarget active = ref.watch(libraryDisplayTargetProvider);
  if (target == active) {
    return snapshot.activeRevision;
  }
  return snapshot.inactiveRevision;
}
