import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_revision_coordinator.g.dart';

const Duration kLibraryInactiveCatalogRefreshDebounce = Duration(seconds: 3);

/// Library sync 进行中：活跃 catalog revision 合并节流间隔。
const Duration kLibrarySyncCatalogRevisionThrottle = Duration(seconds: 2);

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
/// Library sync 进行中：活跃 revision 合并节流，避免亚秒级全量重载。
/// 切库时两侧立即对齐，避免 header 漫画/系列计数短暂互串。
@Riverpod(keepAlive: true)
class LibraryCatalogRevisionCoordinator
    extends _$LibraryCatalogRevisionCoordinator {
  Timer? _inactiveRefreshTimer;
  Timer? _syncThrottleTimer;
  int? _pendingActiveRevision;
  DateTime? _lastActivePushAt;
  bool _librarySyncRunning = false;

  @override
  LibraryCatalogRevisionSnapshot build() {
    ref.onDispose(() {
      _inactiveRefreshTimer?.cancel();
      _syncThrottleTimer?.cancel();
    });

    _librarySyncRunning = ref.read(scanLibraryControllerProvider).running;
    ref.listen<ScanLibraryState>(scanLibraryControllerProvider, (
      ScanLibraryState? previous,
      ScanLibraryState next,
    ) {
      _librarySyncRunning = next.running;
      if ((previous?.running ?? false) && !next.running) {
        _flushPendingActiveRevision();
      }
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
      _flushInactiveRevision();
    });

    ref.listen<AsyncValue<CurrentLibraryState>>(currentLibraryProvider, (
      AsyncValue<CurrentLibraryState>? previous,
      AsyncValue<CurrentLibraryState> next,
    ) {
      final String? previousId = previous?.asData?.value.currentId;
      final String? nextId = next.asData?.value.currentId;
      if (previousId == null || previousId == nextId) {
        return;
      }
      _flushInactiveRevision();
    });

    return const LibraryCatalogRevisionSnapshot(
      activeRevision: 0,
      inactiveRevision: 0,
    );
  }

  void _onRevisionBumped(int revision) {
    _inactiveRefreshTimer?.cancel();

    if (_librarySyncRunning) {
      _pendingActiveRevision = revision;
      final DateTime now = DateTime.now();
      final DateTime? lastPush = _lastActivePushAt;
      if (lastPush != null) {
        final Duration elapsed = now.difference(lastPush);
        if (elapsed < kLibrarySyncCatalogRevisionThrottle) {
          _syncThrottleTimer ??= Timer(
            kLibrarySyncCatalogRevisionThrottle - elapsed,
            _flushPendingActiveRevision,
          );
          return;
        }
      }
    }

    _pushActiveRevision(revision);
  }

  void _flushPendingActiveRevision() {
    _syncThrottleTimer?.cancel();
    _syncThrottleTimer = null;
    final int? pending = _pendingActiveRevision;
    if (pending == null || pending == state.activeRevision) {
      return;
    }
    _pushActiveRevision(pending);
  }

  void _pushActiveRevision(int revision) {
    _pendingActiveRevision = null;
    _lastActivePushAt = DateTime.now();
    state = state.copyWith(activeRevision: revision);
    _inactiveRefreshTimer?.cancel();
    _inactiveRefreshTimer = Timer(kLibraryInactiveCatalogRefreshDebounce, () {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(inactiveRevision: revision);
    });
  }

  void _flushInactiveRevision() {
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
