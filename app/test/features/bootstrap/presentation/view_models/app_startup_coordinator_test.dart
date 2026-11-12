import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/bootstrap/presentation/view_models/app_startup_coordinator_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/domain_event_bus_overrides.dart';

LocalLibrary _lib({required String id, bool scanOnStartup = false}) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledResourceFormatCategories: const <ResourceFormatCategory>[],
    username: '',
    allowHttp: false,
    scanOnStartup: scanOnStartup,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );
}

class _FakeLibrariesNotifier extends LibrariesNotifier {
  _FakeLibrariesNotifier(this._libraries);

  final List<LocalLibrary> _libraries;

  @override
  Future<LibrariesState> build() async {
    return LibrariesState(libraries: _libraries);
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
            librariesProvider.overrideWith(
              () => _FakeLibrariesNotifier(<LocalLibrary>[
                _lib(id: 'a', scanOnStartup: true),
                _lib(id: 'b', scanOnStartup: false),
                _lib(id: 'c', scanOnStartup: true),
              ]),
            ),
            scanLibraryControllerProvider.overrideWith(() => scan),
          ],
        );

        container.read(appStartupCoordinatorProvider);
        await container.read(librariesProvider.future);
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
        scan = _RecordingScanLibraryController()
          ..expectStarts(2)
          ..holdNextStart();
        container = ProviderContainer(
          overrides: <Override>[
            ...domainEventBusOverrides(),
            librariesProvider.overrideWith(
              () => _FakeLibrariesNotifier(<LocalLibrary>[
                _lib(id: 'a', scanOnStartup: true),
                _lib(id: 'c', scanOnStartup: true),
              ]),
            ),
            scanLibraryControllerProvider.overrideWith(() => scan),
          ],
        );

        container.read(appStartupCoordinatorProvider);
        await container.read(librariesProvider.future);
        container.read(libraryRevisionProvider);
        await scan.firstStart.timeout(const Duration(seconds: 2));

        container
            .read(domainEventBusProvider)
            .publish(const LibraryCatalogChanged(CatalogChangeSource.sync));
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
