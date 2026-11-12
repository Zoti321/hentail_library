import 'package:hentai_library/shared/presentation/providers/catalog_state_providers.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/shared/presentation/providers/browse_library_scope_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/library_admin/public.dart';

part 'library_catalog_revision_coordinator.g.dart';

const Duration kLibraryInactiveCatalogRefreshDebounce = Duration(seconds: 3);

/// Catalog revision busy（Library sync 或缩略图后台活跃）时：活跃 revision 合并节流间隔。
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
/// Library sync / 缩略图后台活跃：活跃 revision 合并节流，避免亚秒级全量重载。
/// 切库时两侧立即对齐，避免 header 漫画/系列计数短暂互串。
@Riverpod(keepAlive: true)
class LibraryCatalogRevisionCoordinator
    extends _$LibraryCatalogRevisionCoordinator {
  Timer? _inactiveRefreshTimer;
  Timer? _syncThrottleTimer;
  int? _pendingActiveRevision;
  DateTime? _lastActivePushAt;
  bool _revisionThrottleBusy = false;

  @override
  LibraryCatalogRevisionSnapshot build() {
    ref.onDispose(() {
      _inactiveRefreshTimer?.cancel();
      _syncThrottleTimer?.cancel();
    });

    _revisionThrottleBusy = ref.read(libraryRevisionThrottleBusyStateProvider);
    ref.listen<bool>(libraryRevisionThrottleBusyStateProvider, (
      bool? previous,
      bool next,
    ) {
      _revisionThrottleBusy = next;
      if ((previous ?? false) && !next) {
        _runAfterBuild(_flushPendingActiveRevision);
      }
    });

    ref.listen(libraryRevisionStateProvider, (
      LibraryRevisionState? previous,
      LibraryRevisionState next,
    ) {
      // Initial subscription fires during build; state is seeded below.
      if (previous == null) {
        return;
      }
      if (previous.revision == next.revision) {
        return;
      }
      final int revision = next.revision;
      _runAfterBuild(() => _onRevisionBumped(revision));
    });

    ref.listen(libraryDisplayTargetProvider, (
      LibraryDisplayTarget? previous,
      LibraryDisplayTarget next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _runAfterBuild(_flushInactiveRevision);
    });

    ref.listen<String?>(browseLibraryIdProvider, (
      String? previous,
      String? next,
    ) {
      if (previous == next) {
        return;
      }
      _runAfterBuild(_onBrowseLibraryScopeChanged);
    });

    final int revision = ref.read(libraryRevisionStateProvider).revision;
    return LibraryCatalogRevisionSnapshot(
      activeRevision: revision,
      inactiveRevision: 0,
    );
  }

  /// `ref.listen` may run while a widget is building; defer notifier writes.
  void _runAfterBuild(void Function() action) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      action();
      return;
    }
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      action();
    });
  }

  void _onRevisionBumped(int revision) {
    _inactiveRefreshTimer?.cancel();

    if (_revisionThrottleBusy) {
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

  /// 路由注入 browse 库 id（含 null→有值）时强制两侧 catalog 重载。
  void _onBrowseLibraryScopeChanged() {
    _inactiveRefreshTimer?.cancel();
    _inactiveRefreshTimer = null;
    final int bumped = state.activeRevision + 1;
    state = state.copyWith(activeRevision: bumped, inactiveRevision: bumped);
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
