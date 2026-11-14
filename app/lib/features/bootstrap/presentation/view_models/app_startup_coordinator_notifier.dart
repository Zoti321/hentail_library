import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppStartupCoordinatorNotifier extends _$AppStartupCoordinatorNotifier {
  static const LibraryScanDomainService _scheduler = LibraryScanDomainService();

  int _startupToken = 0;
  bool _startupScheduled = false;
  Timer? _intervalTicker;
  final LibraryScanIntervalSchedule _intervalSchedule =
      LibraryScanIntervalSchedule();
  DateTime Function() _now = DateTime.now;
  final Duration _startupDelay =
      startupDelayForTests ?? const Duration(seconds: 3);
  final bool _scheduleStartupAtIdle = scheduleStartupAtIdleForTests ?? true;

  @visibleForTesting
  // 测试专用可变全局：覆盖启动延迟，无法改为 final。
  // ignore: avoid-global-state
  static Duration? startupDelayForTests;

  @visibleForTesting
  // 测试专用可变全局：覆盖 idle 调度，无法改为 final。
  // ignore: avoid-global-state
  static bool? scheduleStartupAtIdleForTests;

  @visibleForTesting
  set nowOverride(DateTime Function()? value) {
    _now = value ?? DateTime.now;
  }

  @override
  bool build() {
    // Keep coordinator alive from app root. Do not watch libraryRevision /
    // thumbnail progress here — those rebuilds used to bump _startupToken via
    // onDispose and cancel Scan on startup mid-flight.
    ref.onDispose(() {
      _startupToken++;
      _intervalTicker?.cancel();
      _intervalTicker = null;
    });
    ref.listen<AsyncValue<LibrariesState>>(librariesProvider, (
      AsyncValue<LibrariesState>? previous,
      AsyncValue<LibrariesState> next,
    ) {
      next.whenData((LibrariesState state) {
        _intervalSchedule.reconcile(state.libraries, now: _now());
        _ensureIntervalTicker();
        if (!_startupScheduled) {
          _scheduleStartupScansAtIdle(state.libraries);
        }
      });
    }, fireImmediately: true);
    return true;
  }

  void _ensureIntervalTicker() {
    _intervalTicker ??= Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_tickIntervals());
    });
  }

  Future<void> _tickIntervals() async {
    final LibrariesState? state = ref.read(librariesProvider).asData?.value;
    if (state == null) {
      return;
    }
    final DateTime now = _now();
    final List<LocalLibrary> due = _intervalSchedule.dueLibraries(
      state.libraries,
      now: now,
    );
    for (final LocalLibrary library in due) {
      await _startIncrementalQueued(library.libraryId, fromStartup: false);
      _intervalSchedule.advance(library, fallbackAnchor: now);
    }
  }

  void _scheduleStartupScansAtIdle(List<LocalLibrary> libraries) {
    if (_startupScheduled) {
      return;
    }
    _startupScheduled = true;
    _startupToken++;
    final int token = _startupToken;
    final List<String> targets = _scheduler.libraryIdsForStartupScan(libraries);
    if (targets.isEmpty) {
      return;
    }
    // Test / zero-delay path: skip frame+idle scheduling so orchestration is
    // observable without a pumped widget tree.
    if (!_scheduleStartupAtIdle && _startupDelay == Duration.zero) {
      unawaited(_runStartupScans(targets, token));
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((Duration _) async {
      if (_startupDelay > Duration.zero) {
        await Future<void>.delayed(_startupDelay);
      }
      if (!_isValidStartupToken(token)) {
        return;
      }
      await SchedulerBinding.instance.endOfFrame;
      if (!_isValidStartupToken(token)) {
        return;
      }
      if (!_scheduleStartupAtIdle) {
        unawaited(_runStartupScans(targets, token));
        return;
      }
      unawaited(
        SchedulerBinding.instance.scheduleTask<void>(
          () {
            if (!_isValidStartupToken(token)) {
              return;
            }
            unawaited(_runStartupScans(targets, token));
          },
          Priority.idle,
          debugLabel: 'startup_library_scan_idle',
        ),
      );
    });
  }

  Future<void> _runStartupScans(List<String> libraryIds, int token) async {
    for (final String libraryId in libraryIds) {
      if (!_isValidStartupToken(token)) {
        return;
      }
      await _startIncrementalQueued(libraryId, fromStartup: true);
    }
  }

  /// Waits out any in-flight Library sync, then starts incremental sync for [libraryId].
  Future<void> _startIncrementalQueued(
    String libraryId, {
    required bool fromStartup,
  }) async {
    final ScanLibraryController notifier = ref.read(
      scanLibraryControllerProvider.notifier,
    );
    await notifier.waitUntilIdle();
    await notifier.start(
      mode: ScanMode.incremental,
      targetLibraryId: libraryId,
      silent: true,
      fromStartup: fromStartup,
      promptStorageAccess: false,
    );
  }

  bool _isValidStartupToken(int token) {
    return token == _startupToken;
  }
}
