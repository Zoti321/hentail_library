import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/bootstrap/presentation/view_models/app_startup_coordinator_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';

LocalLibrary _lib({
  required String id,
  bool scanOnStartup = false,
  ScanInterval scanInterval = ScanInterval.disabled,
}) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledResourceFormatCategories: const <ResourceFormatCategory>[],
    username: '',
    allowHttp: false,
    scanOnStartup: scanOnStartup,
    scanInterval: scanInterval,
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

  void setLibraries(List<LocalLibrary> libraries) {
    state = AsyncData(LibrariesState(libraries: libraries));
  }
}

typedef _ScanStart = ({
  String? libraryId,
  bool silent,
  bool fromStartup,
  ScanMode mode,
  bool promptStorageAccess,
  bool syncAll,
});

class _RecordingScanLibraryController extends ScanLibraryController {
  final starts = <_ScanStart>[];
  final events = <String>[];
  Completer<void>? idleHold;

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
    events.add('wait');
    if (idleHold case final hold?) await hold.future;
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
      mode: mode,
      promptStorageAccess: promptStorageAccess,
      syncAll: syncAll,
    ));
    events.add('start:$targetLibraryId');
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
  group('AppStartupCoordinator Scan interval', () {
    setUp(() {
      AppStartupCoordinatorNotifier.startupDelayForTests = Duration.zero;
      AppStartupCoordinatorNotifier.scheduleStartupAtIdleForTests = false;
    });
    tearDown(() {
      AppStartupCoordinatorNotifier.startupDelayForTests = null;
      AppStartupCoordinatorNotifier.scheduleStartupAtIdleForTests = null;
    });

    testWidgets(
      'hourly boundary queues silent incremental sync once after completion',
      (tester) async {
        final epoch = DateTime.utc(2026, 1, 1);
        var now = epoch;
        final h = await _intervalHarness(() => now, [
          _lib(id: 'a', scanInterval: ScanInterval.hourly),
        ]);
        try {
          now = epoch.add(const Duration(minutes: 59, seconds: 59));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts, isEmpty);

          h.scan.holdNextStart();
          now = epoch.add(const Duration(hours: 1));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.events, ['wait', 'start:a']);
          expect(h.scan.starts.single, (
            libraryId: 'a',
            silent: true,
            fromStartup: false,
            mode: ScanMode.incremental,
            promptStorageAccess: false,
            syncAll: false,
          ));
          h.scan.releaseHold();
          await tester.pump();
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts, hasLength(1));
        } finally {
          h.container.dispose();
        }
      },
    );

    testWidgets(
      'library updates reset changed intervals and clean disabled or removed anchors',
      (tester) async {
        final epoch = DateTime.utc(2026, 1, 1);
        var now = epoch;
        final h = await _intervalHarness(() => now, [
          for (final id in ['a', 'b', 'c'])
            _lib(id: id, scanInterval: ScanInterval.hourly),
        ]);
        try {
          now = epoch.add(const Duration(minutes: 50));
          h.libraries.setLibraries([
            _lib(id: 'a', scanInterval: ScanInterval.every6Hours),
            _lib(id: 'b'),
          ]);
          await tester.pump();
          now = epoch.add(const Duration(hours: 1));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts, isEmpty);
          h.libraries.setLibraries([
            _lib(id: 'a', scanInterval: ScanInterval.every6Hours),
            _lib(id: 'b', scanInterval: ScanInterval.hourly),
            _lib(id: 'c', scanInterval: ScanInterval.hourly),
          ]);
          await tester.pump();
          now = epoch.add(const Duration(hours: 1, minutes: 59, seconds: 59));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts, isEmpty);
          now = epoch.add(const Duration(hours: 2));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts.map((s) => s.libraryId), ['b', 'c']);

          h.libraries.setLibraries([
            _lib(id: 'a', scanInterval: ScanInterval.every6Hours),
          ]);
          await tester.pump();
          now = epoch.add(const Duration(hours: 6, minutes: 49, seconds: 59));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts, hasLength(2));
          now = epoch.add(const Duration(hours: 6, minutes: 50));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts.map((s) => s.libraryId), ['b', 'c', 'a']);
        } finally {
          h.container.dispose();
        }
      },
    );

    testWidgets(
      'a changed interval while waiting advances the latest anchor using the queued snapshot period',
      (tester) async {
        final epoch = DateTime.utc(2026, 1, 1);
        var now = epoch;
        final h = await _intervalHarness(() => now, [
          _lib(id: 'a', scanInterval: ScanInterval.hourly),
        ]);
        try {
          h.scan.idleHold = Completer<void>();
          now = epoch.add(const Duration(hours: 1));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.events, ['wait']);
          expect(h.scan.starts, isEmpty);
          now = epoch.add(const Duration(hours: 1, minutes: 30));
          h.libraries.setLibraries([
            _lib(id: 'a', scanInterval: ScanInterval.every6Hours),
          ]);
          await tester.pump();
          h.scan.idleHold!.complete();
          await tester.pump();
          expect(h.scan.events, ['wait', 'start:a']);

          // New anchor 01:30 + queued hourly period = 02:30; next due is 08:30.
          now = epoch.add(const Duration(hours: 8, minutes: 29, seconds: 59));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts, hasLength(1));
          now = epoch.add(const Duration(hours: 8, minutes: 30));
          await tester.pump(const Duration(seconds: 30));
          expect(h.scan.starts.map((s) => s.libraryId), ['a', 'a']);
        } finally {
          h.container.dispose();
        }
      },
    );
  });

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

Future<
  ({
    ProviderContainer container,
    _FakeLibrariesNotifier libraries,
    _RecordingScanLibraryController scan,
  })
>
_intervalHarness(DateTime Function() now, List<LocalLibrary> initial) async {
  final libraries = _FakeLibrariesNotifier(initial);
  final scan = _RecordingScanLibraryController();
  final container = ProviderContainer(
    overrides: [
      librariesProvider.overrideWith(() => libraries),
      scanLibraryControllerProvider.overrideWith(() => scan),
    ],
  );
  container.read(appStartupCoordinatorProvider);
  container.read(appStartupCoordinatorProvider.notifier).nowOverride = now;
  await container.read(librariesProvider.future);
  return (container: container, libraries: libraries, scan: scan);
}
