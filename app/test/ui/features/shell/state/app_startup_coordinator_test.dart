import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/state/app_startup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';

LocalLibrary _lib({required String id, bool scanOnStartup = false}) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledFormatGroups: const <FormatGroup>[],
    username: '',
    allowHttp: false,
    scanOnStartup: scanOnStartup,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );
}

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  _FakeLibraryRevisionPort(this._events);

  final StreamController<void> _events;

  @override
  Stream<void> watchRevision() => _events.stream;
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  _FakeCurrentLibraryNotifier(this._libraries);

  final List<LocalLibrary> _libraries;

  @override
  Future<CurrentLibraryState> build() async {
    return CurrentLibraryState(
      libraries: _libraries,
      currentId: _libraries.isEmpty ? null : _libraries.first.libraryId,
    );
  }
}

class _RecordingScanLibraryController extends ScanLibraryController {
  final List<({String? libraryId, bool silent, bool fromStartup})> starts =
      <({String? libraryId, bool silent, bool fromStartup})>[];

  final Completer<void> _firstStart = Completer<void>();
  final Completer<void> _allDone = Completer<void>();
  int _expectedStarts = 0;
  Completer<void>? _hold;
  Future<void>? _future;

  Future<void> get firstStart => _firstStart.future;
  Future<void> get allDone => _allDone.future;

  void expectStarts(int count) {
    _expectedStarts = count;
  }

  void holdNextStart() {
    _hold = Completer<void>();
  }

  void releaseHold() {
    _hold?.complete();
    _hold = null;
  }

  @override
  ScanLibraryState build() => const ScanLibraryState();

  @override
  Future<void> waitUntilIdle() async {
    while (state.running) {
      final Future<void>? inFlight = _future;
      if (inFlight == null) {
        return;
      }
      await inFlight;
    }
  }

  @override
  Future<void> start({
    ScanMode mode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    bool silent = false,
    bool fromStartup = false,
    bool promptStorageAccess = true,
  }) {
    if (state.running) {
      return _future ?? Future<void>.value();
    }

    starts.add((
      libraryId: targetLibraryId,
      silent: silent,
      fromStartup: fromStartup,
    ));
    if (!_firstStart.isCompleted) {
      _firstStart.complete();
    }

    state = state.copyWith(
      running: true,
      silent: silent,
      fromStartup: fromStartup,
      scanMode: mode,
      cancelled: false,
      error: null,
      progress: null,
    );

    _future = () async {
      final Completer<void>? hold = _hold;
      if (hold != null) {
        await hold.future;
      }
      state = state.copyWith(
        running: false,
        progress: (
          phase: SyncLibraryPhase.done,
          route: SyncLibraryRoute.withRoots,
          currentPath: null,
          acceptedTotal: 0,
          counts: emptyLibrarySyncCounts(),
          removedCount: 0,
          addedCount: 0,
          keptCount: 0,
          migratedCount: 0,
          thumbnailTotal: null,
          thumbnailDone: null,
          thumbnailFailedCount: null,
          errorMessage: null,
        ),
      );
      if (_expectedStarts > 0 &&
          starts.length >= _expectedStarts &&
          !_allDone.isCompleted) {
        _allDone.complete();
      }
    }();
    return _future!;
  }
}

void main() {
  group('AppStartupCoordinator Scan on startup', () {
    late _RecordingScanLibraryController scan;
    late ProviderContainer container;

    setUp(() {
      AppStartupCoordinatorNotifier.startupDelayForTests = Duration.zero;
      AppStartupCoordinatorNotifier.scheduleStartupAtIdleForTests = false;
    });

    tearDown(() {
      container.dispose();
      AppStartupCoordinatorNotifier.startupDelayForTests = null;
      AppStartupCoordinatorNotifier.scheduleStartupAtIdleForTests = null;
    });

    test(
      'starts incremental silent sync for every Scan on startup library',
      () async {
        scan = _RecordingScanLibraryController()..expectStarts(2);
        container = ProviderContainer(
          overrides: <Override>[
            currentLibraryProvider.overrideWith(
              () => _FakeCurrentLibraryNotifier(<LocalLibrary>[
                _lib(id: 'a', scanOnStartup: true),
                _lib(id: 'b', scanOnStartup: false),
                _lib(id: 'c', scanOnStartup: true),
              ]),
            ),
            scanLibraryControllerProvider.overrideWith(() => scan),
          ],
        );

        container.read(appStartupCoordinatorProvider);
        await container.read(currentLibraryProvider.future);
        await scan.allDone.timeout(const Duration(seconds: 2));

        expect(scan.starts.length, 2);
        expect(scan.starts.map((e) => e.libraryId).toList(), <String>[
          'a',
          'c',
        ]);
        expect(scan.starts.every((e) => e.silent && e.fromStartup), isTrue);
      },
    );

    test(
      'library revision bumps during startup do not cancel remaining scans',
      () async {
        final StreamController<void> revisionEvents =
            StreamController<void>.broadcast();
        addTearDown(revisionEvents.close);

        scan = _RecordingScanLibraryController()
          ..expectStarts(2)
          ..holdNextStart();
        container = ProviderContainer(
          overrides: <Override>[
            libraryRevisionPortProvider.overrideWithValue(
              _FakeLibraryRevisionPort(revisionEvents),
            ),
            currentLibraryProvider.overrideWith(
              () => _FakeCurrentLibraryNotifier(<LocalLibrary>[
                _lib(id: 'a', scanOnStartup: true),
                _lib(id: 'c', scanOnStartup: true),
              ]),
            ),
            scanLibraryControllerProvider.overrideWith(() => scan),
          ],
        );

        container.read(appStartupCoordinatorProvider);
        await container.read(currentLibraryProvider.future);
        container.read(libraryRevisionProvider);
        await scan.firstStart.timeout(const Duration(seconds: 2));

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        scan.releaseHold();
        await scan.allDone.timeout(const Duration(seconds: 2));

        expect(scan.starts.map((e) => e.libraryId).toList(), <String>[
          'a',
          'c',
        ]);
      },
    );
  });
}
