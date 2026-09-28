import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_probe_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocalLibrary _lib(String id) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledFormatGroups: const <FormatGroup>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  _FakeCurrentLibraryNotifier(this._libraries);

  final List<LocalLibrary> _libraries;

  @override
  Future<CurrentLibraryState> build() async {
    return CurrentLibraryState(
      libraries: _libraries,
      currentId: _libraries.first.libraryId,
    );
  }
}

class _RecordingHomePageRepository implements HomePageRepository {
  final List<String> probedLibraryIds = <String>[];

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) =>
      const Stream<HomePageCounts>.empty();

  @override
  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  }) => const Stream<List<HomeContinueReadingEntry>>.empty();

  @override
  Stream<List<HomeLibraryAlert>> watchHomeLibraryAlerts() =>
      const Stream<List<HomeLibraryAlert>>.empty();

  @override
  Stream<List<HomeRecentlyAddedEntry>> watchRecentlyAddedOnHome({
    required bool excludeR18,
  }) => const Stream<List<HomeRecentlyAddedEntry>>.empty();

  @override
  Future<LibraryProbeResult> probeLibrary({
    required String libraryId,
    String? password,
  }) async {
    probedLibraryIds.add(libraryId);
    return LibraryProbeResult(
      libraryId: libraryId,
      addedCount: 1,
      changedCount: 0,
      removedCount: 0,
      unreachable: false,
      probedAt: DateTime.utc(2026, 1, 1),
      baselineMissing: false,
    );
  }
}

class _RecordingScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}

Future<void> _waitForProbeCycle() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeProbeCoordinator', () {
    late _RecordingHomePageRepository repo;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repo = _RecordingHomePageRepository();
      HomeProbeCoordinator.idleDelayForTests = Duration.zero;
      HomeProbeCoordinator.homeVisibleDebounceForTests = Duration.zero;
      HomeProbeCoordinator.probeDebounceForTests = Duration.zero;
      HomeProbeCoordinator.scheduleProbeAtIdleForTests = false;
    });

    tearDown(() {
      container.dispose();
      HomeProbeCoordinator.idleDelayForTests = null;
      HomeProbeCoordinator.homeVisibleDebounceForTests = const Duration(
        milliseconds: 500,
      );
      HomeProbeCoordinator.probeDebounceForTests = const Duration(minutes: 15);
      HomeProbeCoordinator.scheduleProbeAtIdleForTests = true;
    });

    test('does not probe when home page is not visible', () async {
      container = ProviderContainer(
        overrides: <Override>[
          homePageRepoProvider.overrideWithValue(repo),
          currentLibraryProvider.overrideWith(
            () => _FakeCurrentLibraryNotifier(<LocalLibrary>[_lib('lib-a')]),
          ),
          scanLibraryControllerProvider.overrideWith(
            _RecordingScanLibraryController.new,
          ),
        ],
      );

      container.read(homeProbeCoordinatorProvider);
      await container.read(currentLibraryProvider.future);
      await _waitForProbeCycle();

      expect(repo.probedLibraryIds, isEmpty);
    });

    test('probes libraries after home becomes visible', () async {
      container = ProviderContainer(
        overrides: <Override>[
          homePageRepoProvider.overrideWithValue(repo),
          currentLibraryProvider.overrideWith(
            () => _FakeCurrentLibraryNotifier(<LocalLibrary>[_lib('lib-a')]),
          ),
          scanLibraryControllerProvider.overrideWith(
            _RecordingScanLibraryController.new,
          ),
        ],
      );

      container.read(homeProbeCoordinatorProvider);
      await container.read(currentLibraryProvider.future);
      container.read(homePageVisibleProvider.notifier).setVisible(true);
      await _waitForProbeCycle();

      expect(repo.probedLibraryIds, <String>['lib-a']);
    });

    test('respects per-library debounce', () async {
      HomeProbeCoordinator.probeDebounceForTests = const Duration(hours: 1);
      container = ProviderContainer(
        overrides: <Override>[
          homePageRepoProvider.overrideWithValue(repo),
          currentLibraryProvider.overrideWith(
            () => _FakeCurrentLibraryNotifier(<LocalLibrary>[_lib('lib-a')]),
          ),
          scanLibraryControllerProvider.overrideWith(
            _RecordingScanLibraryController.new,
          ),
        ],
      );

      container.read(homeProbeCoordinatorProvider);
      await container.read(currentLibraryProvider.future);
      container.read(homePageVisibleProvider.notifier).setVisible(true);
      await _waitForProbeCycle();
      expect(repo.probedLibraryIds, <String>['lib-a']);

      container.read(homePageVisibleProvider.notifier).setVisible(false);
      container.read(homePageVisibleProvider.notifier).setVisible(true);
      await _waitForProbeCycle();

      expect(repo.probedLibraryIds, <String>['lib-a']);
    });

    test('waits for home visibility debounce before probing', () async {
      HomeProbeCoordinator.homeVisibleDebounceForTests = const Duration(
        milliseconds: 80,
      );
      container = ProviderContainer(
        overrides: <Override>[
          homePageRepoProvider.overrideWithValue(repo),
          currentLibraryProvider.overrideWith(
            () => _FakeCurrentLibraryNotifier(<LocalLibrary>[_lib('lib-a')]),
          ),
          scanLibraryControllerProvider.overrideWith(
            _RecordingScanLibraryController.new,
          ),
        ],
      );

      container.read(homeProbeCoordinatorProvider);
      await container.read(currentLibraryProvider.future);
      container.read(homePageVisibleProvider.notifier).setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.probedLibraryIds, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(repo.probedLibraryIds, <String>['lib-a']);
    });

    test('skips probe while library sync is running', () async {
      final _RecordingScanLibraryController scan =
          _RecordingScanLibraryController();
      container = ProviderContainer(
        overrides: <Override>[
          homePageRepoProvider.overrideWithValue(repo),
          currentLibraryProvider.overrideWith(
            () => _FakeCurrentLibraryNotifier(<LocalLibrary>[_lib('lib-a')]),
          ),
          scanLibraryControllerProvider.overrideWith(() => scan),
        ],
      );

      container.read(homeProbeCoordinatorProvider);
      await container.read(currentLibraryProvider.future);
      scan.state = scan.state.copyWith(running: true);
      container.read(homePageVisibleProvider.notifier).setVisible(true);
      await _waitForProbeCycle();

      expect(repo.probedLibraryIds, isEmpty);
    });
  });
}
