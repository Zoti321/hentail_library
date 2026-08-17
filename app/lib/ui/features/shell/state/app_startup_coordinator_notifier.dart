import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/domain/library/library_scan_scheduler.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppStartupCoordinatorNotifier extends _$AppStartupCoordinatorNotifier {
  static const LibraryScanScheduler _scheduler = LibraryScanScheduler();

  int _startupToken = 0;
  bool _startupScheduled = false;
  Timer? _intervalTicker;
  final Map<String, DateTime> _intervalAnchors = <String, DateTime>{};
  final Map<String, ScanInterval> _lastIntervals = <String, ScanInterval>{};
  DateTime Function() _now = DateTime.now;

  @visibleForTesting
  set nowOverride(DateTime Function()? value) {
    _now = value ?? DateTime.now;
  }

  @override
  bool build() {
    ref.watch(libraryRevisionProvider);
    ref.watch(thumbnailEventCoordinatorProvider);
    ref.onDispose(() {
      _startupToken++;
      _intervalTicker?.cancel();
      _intervalTicker = null;
    });
    ref.listen<AsyncValue<CurrentLibraryState>>(currentLibraryProvider, (
      AsyncValue<CurrentLibraryState>? previous,
      AsyncValue<CurrentLibraryState> next,
    ) {
      next.whenData((CurrentLibraryState state) {
        _syncIntervalAnchors(state.libraries);
        _ensureIntervalTicker();
        if (!_startupScheduled) {
          _scheduleStartupScansAtIdle(state.libraries);
        }
      });
    });
    return true;
  }

  void _syncIntervalAnchors(List<LocalLibrary> libraries) {
    final DateTime now = _now();
    final Set<String> alive = libraries
        .map((LocalLibrary library) => library.libraryId)
        .toSet();
    _intervalAnchors.removeWhere((String id, _) => !alive.contains(id));
    _lastIntervals.removeWhere((String id, _) => !alive.contains(id));

    for (final LocalLibrary library in libraries) {
      final String id = library.libraryId;
      final ScanInterval previous = _lastIntervals[id] ?? ScanInterval.disabled;
      _lastIntervals[id] = library.scanInterval;
      if (library.scanInterval == ScanInterval.disabled) {
        _intervalAnchors.remove(id);
        continue;
      }
      if (previous != library.scanInterval ||
          !_intervalAnchors.containsKey(id)) {
        _intervalAnchors[id] = now;
      }
    }
  }

  void _ensureIntervalTicker() {
    _intervalTicker ??= Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_tickIntervals());
    });
  }

  Future<void> _tickIntervals() async {
    final CurrentLibraryState? state = ref
        .read(currentLibraryProvider)
        .asData
        ?.value;
    if (state == null) {
      return;
    }
    final DateTime now = _now();
    final List<String> due = _scheduler.libraryIdsDueForInterval(
      libraries: state.libraries,
      intervalAnchors: Map<String, DateTime>.from(_intervalAnchors),
      now: now,
    );
    for (final String libraryId in due) {
      await _startIncrementalQueued(libraryId);
      LocalLibrary? matched;
      for (final LocalLibrary library in state.libraries) {
        if (library.libraryId == libraryId) {
          matched = library;
          break;
        }
      }
      final Duration? period = matched?.scanInterval.period;
      final DateTime anchor = _intervalAnchors[libraryId] ?? now;
      _intervalAnchors[libraryId] = period == null ? now : anchor.add(period);
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
    WidgetsBinding.instance.addPostFrameCallback((Duration _) async {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!_isValidStartupToken(token)) {
        return;
      }
      await SchedulerBinding.instance.endOfFrame;
      if (!_isValidStartupToken(token)) {
        return;
      }
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (!_isValidStartupToken(token)) {
            return;
          }
          unawaited(_runStartupScans(targets, token));
        },
        Priority.idle,
        debugLabel: 'startup_library_scan_idle',
      );
    });
  }

  Future<void> _runStartupScans(List<String> libraryIds, int token) async {
    for (final String libraryId in libraryIds) {
      if (!_isValidStartupToken(token)) {
        return;
      }
      await _startIncrementalQueued(libraryId);
    }
  }

  /// Waits out any in-flight Library sync, then starts incremental sync for [libraryId].
  Future<void> _startIncrementalQueued(String libraryId) async {
    final ScanLibraryController notifier = ref.read(
      scanLibraryControllerProvider.notifier,
    );
    while (ref.read(scanLibraryControllerProvider).running) {
      await notifier.start();
    }
    await notifier.start(
      mode: ScanMode.incremental,
      targetLibraryId: libraryId,
      silent: true,
    );
  }

  bool _isValidStartupToken(int token) {
    return token == _startupToken;
  }
}
