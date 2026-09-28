import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_alert_dismiss_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_probe_coordinator_notifier.g.dart';

const Duration _kProbeDebounce = Duration(minutes: 15);
const Duration _kHomeVisibleDebounce = Duration(milliseconds: 500);

/// Home 页是否在前台；由 [HomePage] 挂载/卸载时更新，供 probe 调度门控。
class HomePageVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) {
    if (state != visible) {
      state = visible;
    }
  }
}

final homePageVisibleProvider = NotifierProvider<HomePageVisibleNotifier, bool>(
  HomePageVisibleNotifier.new,
);

/// [HomePage] 挂载期间保持 `homePageVisibleProvider` 为 true；卸载后自动复位。
final homePageVisibilityLifecycleProvider = Provider.autoDispose<void>((
  Ref ref,
) {
  final HomePageVisibleNotifier visibleNotifier = ref.read(
    homePageVisibleProvider.notifier,
  );
  ref.onDispose(() {
    visibleNotifier.setVisible(false);
  });
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ref.mounted) {
      visibleNotifier.setVisible(true);
    }
  });
});

@Riverpod(keepAlive: true)
class HomeProbeResults extends _$HomeProbeResults {
  @override
  Map<String, LibraryProbeResult> build() => <String, LibraryProbeResult>{};

  void upsert(LibraryProbeResult result) {
    state = <String, LibraryProbeResult>{...state, result.libraryId: result};
  }
}

@Riverpod(keepAlive: true)
class HomeProbeCoordinator extends _$HomeProbeCoordinator {
  final Map<String, DateTime> _lastProbedAt = <String, DateTime>{};
  Timer? _idleTimer;
  Timer? _visibleTimer;
  int _runToken = 0;

  @visibleForTesting
  static Duration? idleDelayForTests;

  @visibleForTesting
  static Duration homeVisibleDebounceForTests = _kHomeVisibleDebounce;

  @visibleForTesting
  static Duration probeDebounceForTests = _kProbeDebounce;

  @visibleForTesting
  static bool scheduleProbeAtIdleForTests = true;

  @override
  bool build() {
    ref.onDispose(() {
      _runToken++;
      _idleTimer?.cancel();
      _visibleTimer?.cancel();
    });
    ref.listen<bool>(homePageVisibleProvider, (bool? _, bool visible) {
      if (visible) {
        final List<LocalLibrary> libraries =
            ref.read(currentLibraryProvider).asData?.value.libraries ??
            const <LocalLibrary>[];
        _scheduleProbeWhenHomeVisible(libraries);
      } else {
        _idleTimer?.cancel();
        _visibleTimer?.cancel();
      }
    });
    ref.listen<AsyncValue<CurrentLibraryState>>(currentLibraryProvider, (
      AsyncValue<CurrentLibraryState>? _,
      AsyncValue<CurrentLibraryState> next,
    ) {
      next.whenData((CurrentLibraryState state) {
        _scheduleProbeWhenHomeVisible(state.libraries);
      });
    }, fireImmediately: true);
    ref.listen<ScanLibraryState>(scanLibraryControllerProvider, (
      ScanLibraryState? previous,
      ScanLibraryState next,
    ) {
      if (previous?.running == true && !next.running) {
        final List<LocalLibrary> libraries =
            ref.read(currentLibraryProvider).asData?.value.libraries ??
            const <LocalLibrary>[];
        _scheduleProbeWhenHomeVisible(libraries, immediate: true);
      }
    });
    return true;
  }

  void _scheduleProbeWhenHomeVisible(
    List<LocalLibrary> libraries, {
    bool immediate = false,
  }) {
    if (!ref.read(homePageVisibleProvider)) {
      return;
    }
    _visibleTimer?.cancel();
    final Duration visibleDelay = immediate
        ? Duration.zero
        : homeVisibleDebounceForTests;
    _visibleTimer = Timer(visibleDelay, () {
      if (!ref.read(homePageVisibleProvider)) {
        return;
      }
      _scheduleIdleProbe(libraries, immediate: immediate);
    });
  }

  void _scheduleIdleProbe(
    List<LocalLibrary> libraries, {
    bool immediate = false,
  }) {
    _idleTimer?.cancel();
    final Duration delay = immediate
        ? Duration.zero
        : (idleDelayForTests ?? const Duration(seconds: 2));
    _idleTimer = Timer(delay, () {
      if (!ref.read(homePageVisibleProvider)) {
        return;
      }
      if (scheduleProbeAtIdleForTests) {
        SchedulerBinding.instance.scheduleTask<void>(
          () => unawaited(_probeDueLibraries(libraries)),
          Priority.idle,
        );
      } else {
        unawaited(_probeDueLibraries(libraries));
      }
    });
  }

  Future<void> _probeDueLibraries(List<LocalLibrary> libraries) async {
    if (ref.read(scanLibraryControllerProvider).running) {
      return;
    }
    final int token = ++_runToken;
    final HomePageRepository repository = ref.read(homePageRepoProvider);
    final DateTime now = DateTime.now();
    final Duration debounce = probeDebounceForTests;
    for (final LocalLibrary library in libraries) {
      if (token != _runToken) {
        return;
      }
      if (ref.read(scanLibraryControllerProvider).running) {
        return;
      }
      final DateTime? last = _lastProbedAt[library.libraryId];
      if (last != null && now.difference(last) < debounce) {
        continue;
      }
      try {
        final LibraryProbeResult result = await repository.probeLibrary(
          libraryId: library.libraryId,
        );
        if (token != _runToken) {
          return;
        }
        _lastProbedAt[library.libraryId] = now;
        ref.read(homeProbeResultsProvider.notifier).upsert(result);
        await ref
            .read(homeAlertDismissStoreProvider.notifier)
            .clearForLibraryKind(
              library.libraryId,
              HomeLibraryAlertKind.pendingResourcesDetected,
            );
      } catch (_) {
        // Probe failures are non-fatal; next idle cycle retries after debounce.
      }
    }
  }
}
