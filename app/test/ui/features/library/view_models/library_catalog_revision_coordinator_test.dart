import 'dart:async';

import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_revision_coordinator.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
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

void main() {
  group('LibraryCatalogRevisionCoordinator', () {
    late StreamController<void> events;
    late _FakeCurrentLibraryNotifier currentLibrary;
    late ProviderContainer container;

    setUp(() {
      events = StreamController<void>.broadcast();
      currentLibrary = _FakeCurrentLibraryNotifier(currentId: 'lib-a');
      container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(events),
          ),
          currentLibraryProvider.overrideWith(() => currentLibrary),
        ],
      );
      // Warm keepAlive providers so listens are attached and notifiers init.
      container.read(currentLibraryProvider);
      container.read(libraryRevisionProvider);
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
  });
}
