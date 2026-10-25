import 'dart:async';

import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';

import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/shared/domain/library/format_group.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_revision_coordinator.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/shared/di/comic_cover_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  _FakeLibraryRevisionPort(this._events);

  final StreamController<void> _events;

  @override
  Stream<void> watchRevision() => _events.stream;
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  _FakeCurrentLibraryNotifier({required this.currentId});

  String? currentId;

  static const LocalLibrary _libraryA = (
    libraryId: 'lib-a',
    kind: 'local',
    rootPath: '/a',
    name: 'A',
    enabledFormatGroups: <FormatGroup>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );

  static const LocalLibrary _libraryB = (
    libraryId: 'lib-b',
    kind: 'local',
    rootPath: '/b',
    name: 'B',
    enabledFormatGroups: <FormatGroup>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );

  @override
  Future<CurrentLibraryState> build() async {
    return CurrentLibraryState(
      libraries: const <LocalLibrary>[_libraryA, _libraryB],
      currentId: currentId,
    );
  }

  void setCurrentIdSync(String libraryId) {
    currentId = libraryId;
    state = AsyncData(
      CurrentLibraryState(
        libraries: const <LocalLibrary>[_libraryA, _libraryB],
        currentId: libraryId,
      ),
    );
  }
}

class _ControllableScanLibraryController extends ScanLibraryController {
  _ControllableScanLibraryController({required this._running});

  bool _running;

  @override
  ScanLibraryState build() => ScanLibraryState(running: _running);

  void setRunning(bool running) {
    _running = running;
    state = state.copyWith(running: running);
  }
}

class _ControllableThumbnailEventCoordinator extends ThumbnailEventCoordinator {
  _ControllableThumbnailEventCoordinator()
    : _progress = const ThumbnailBackgroundProgress();

  ThumbnailBackgroundProgress _progress;

  @override
  ThumbnailBackgroundProgress build() => _progress;

  void setProgress(ThumbnailBackgroundProgress progress) {
    _progress = progress;
    state = progress;
  }
}

void main() {
  group('LibraryCatalogRevisionCoordinator', () {
    late StreamController<void> events;
    late _FakeCurrentLibraryNotifier currentLibrary;
    late _ControllableScanLibraryController scanLibrary;
    late _ControllableThumbnailEventCoordinator thumbnails;
    late ProviderContainer container;

    setUp(() {
      events = StreamController<void>.broadcast();
      currentLibrary = _FakeCurrentLibraryNotifier(currentId: 'lib-a');
      scanLibrary = _ControllableScanLibraryController(running: false);
      thumbnails = _ControllableThumbnailEventCoordinator();
      container = ProviderContainer(
        overrides: <Override>[
          ...sharedLibraryStateOverrides(),
          ...bootstrapCompositionOverrides(),
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(events),
          ),
          currentLibraryProvider.overrideWith(() => currentLibrary),
          scanLibraryControllerProvider.overrideWith(() => scanLibrary),
          thumbnailEventCoordinatorProvider.overrideWith(() => thumbnails),
        ],
      );
      // Warm keepAlive providers so listens are attached and notifiers init.
      container.read(currentLibraryProvider);
      container.read(libraryRevisionProvider);
      container.read(scanLibraryControllerProvider);
      container.read(thumbnailEventCoordinatorProvider);
      container.read(libraryCatalogRevisionCoordinatorProvider);
    });

    tearDown(() async {
      container.dispose();
      await events.close();
    });

    test(
      'sync revision bump refreshes active tab immediately and defers inactive',
      () {
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();

        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
        );
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.series),
          ),
          0,
        );
      },
    );

    test(
      'current library change flushes inactive catalog revision immediately',
      () {
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.series),
          ),
          0,
        );

        // Mirrors CurrentLibraryNotifier.select: revision first, then id.
        currentLibrary.setCurrentIdSync('lib-b');

        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
        );
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.series),
          ),
          1,
        );
      },
    );

    test(
      'library sync running throttles active catalog revision bumps',
      () async {
        scanLibrary.setRunning(true);
        // Allow listen to observe running=true before bumps.
        await Future<void>.delayed(Duration.zero);

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
        );

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
          reason: 'subsequent bumps during sync stay merged until throttle',
        );

        await Future<void>.delayed(
          kLibrarySyncCatalogRevisionThrottle +
              const Duration(milliseconds: 50),
        );

        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          3,
        );
      },
    );

    test(
      'library sync settle flushes pending active catalog revision',
      () async {
        scanLibrary.setRunning(true);
        await Future<void>.delayed(Duration.zero);

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        // 每次 bump 之间读取一次，使 listener 逐次观察到 revision（避免同步批次被合并）。
        container.read(
          libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
        );
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
        );

        scanLibrary.setRunning(false);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          2,
        );
      },
    );

    test(
      'thumbnail background active throttles active catalog revision bumps',
      () async {
        thumbnails.setProgress(
          const ThumbnailBackgroundProgress(done: 1, total: 10),
        );
        await Future<void>.delayed(Duration.zero);

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
        );

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
          reason: 'subsequent bumps during thumbnail busy stay merged',
        );

        await Future<void>.delayed(
          kLibrarySyncCatalogRevisionThrottle +
              const Duration(milliseconds: 50),
        );

        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          3,
        );
      },
    );

    test(
      'thumbnail background settle flushes pending active catalog revision',
      () async {
        thumbnails.setProgress(
          const ThumbnailBackgroundProgress(done: 0, total: 5),
        );
        await Future<void>.delayed(Duration.zero);

        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        // 每次 bump 之间读取一次，使 listener 逐次观察到 revision（避免同步批次被合并）。
        container.read(
          libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
        );
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();
        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          1,
        );

        // Sync already idle; only thumbnails keep busy — settle should flush.
        thumbnails.setProgress(
          const ThumbnailBackgroundProgress(done: 5, total: 5),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(
            libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
          ),
          2,
        );
      },
    );

    test('sync settle while thumbnails active does not flush yet', () async {
      scanLibrary.setRunning(true);
      thumbnails.setProgress(
        const ThumbnailBackgroundProgress(done: 0, total: 3),
      );
      await Future<void>.delayed(Duration.zero);

      container.read(libraryRevisionProvider.notifier).notifyExternalChange();
      // 每次 bump 之间读取一次，使 listener 逐次观察到 revision（避免同步批次被合并）。
      container.read(
        libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
      );
      container.read(libraryRevisionProvider.notifier).notifyExternalChange();
      expect(
        container.read(
          libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
        ),
        1,
      );

      scanLibrary.setRunning(false);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(
          libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
        ),
        1,
        reason: 'thumbnail backlog keeps busy after sync Done',
      );

      thumbnails.setProgress(
        const ThumbnailBackgroundProgress(done: 3, total: 3),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(
          libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics),
        ),
        2,
      );
    });
  });
}
