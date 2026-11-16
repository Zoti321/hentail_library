import 'dart:async';

import 'package:hentai_library/features/library_admin/application/library_sync_exception.dart';
import 'package:hentai_library/features/library_admin/infrastructure/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:test/test.dart';

class _CredRepo implements LibraryRepository {
  _CredRepo({required this.libraries, required this.passwords});

  final List<LocalLibrary> libraries;
  final Map<String, String?> passwords;

  @override
  Future<List<LocalLibrary>> list() async => libraries;

  @override
  Future<String?> readRemotePassword(String libraryId) async =>
      passwords[libraryId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingCredentialsRepo implements LibraryRepository {
  final Completer<String?> password = Completer<String?>();
  final Completer<void> passwordRequested = Completer<void>();

  @override
  Future<List<LocalLibrary>> list() async => [
    _lib(id: 'remote', kind: 'remote'),
  ];

  @override
  Future<String?> readRemotePassword(String libraryId) {
    passwordRequested.complete();
    return password.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Handle implements rust.SyncHandleDto {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SyncApi implements RustLibApi {
  final List<rust.SyncHandleDto> created = [];
  final List<rust.SyncHandleDto> cancelled = [];
  final Map<rust.SyncHandleDto, StreamController<rust.SyncLibraryProgressDto>>
  streams = {};
  final List<rust.SyncHandleDto> started = [];
  final List<Completer<void>> streamStarted = [
    Completer<void>(),
    Completer<void>(),
  ];

  @override
  rust.SyncHandleDto crateApiSyncCreateSyncHandleFrb() {
    final handle = _Handle();
    created.add(handle);
    streams[handle] = StreamController<rust.SyncLibraryProgressDto>();
    return handle;
  }

  @override
  void crateApiSyncCancelSyncFrb({required rust.SyncHandleDto handle}) =>
      cancelled.add(handle);

  @override
  Stream<rust.SyncLibraryProgressDto> crateApiSyncSyncLibraryFrb({
    required rust.SyncHandleDto handle,
    required rust.SyncScanModeDto scanMode,
    required bool syncAll,
    String? targetLibraryId,
    required List<rust.RemoteLibraryCredentialDto> credentials,
  }) {
    started.add(handle);
    streamStarted[started.length - 1].complete();
    return streams[handle]!.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

LocalLibrary _lib({required String id, required String kind}) => (
  libraryId: id,
  kind: kind,
  rootPath: kind == 'remote' ? 'https://example/dav' : 'C:/lib',
  name: id,
  enabledResourceFormatCategories: ResourceFormatCategory.all,
  username: kind == 'remote' ? 'u' : '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: true,
  sidebarOrder: 0,
);

void main() {
  test(
    'older stream cleanup cannot clear the active restarted handle',
    () async {
      final api = _SyncApi();
      RustLib.initMock(api: api);
      addTearDown(RustLib.dispose);
      final adapter = SyncLibraryFrbAdapter(
        libraryRepository: _CredRepo(libraries: [], passwords: {}),
      );
      final first = adapter.call(isCancelled: () => false);
      await api.streamStarted[0].future;
      adapter.cancelActive();
      final second = adapter.call(isCancelled: () => false);
      await api.streamStarted[1].future;
      final firstHandle = api.created[0];
      final secondHandle = api.created[1];
      await api.streams[firstHandle]!.close();
      await first;
      adapter.cancelActive();
      final cancelledWhileSecondRunning = List<rust.SyncHandleDto>.of(
        api.cancelled,
      );
      await api.streams[secondHandle]!.close();
      await second;
      adapter.cancelActive();
      expect(cancelledWhileSecondRunning, [firstHandle, secondHandle]);
      expect(api.cancelled, [firstHandle, secondHandle]);
    },
  );

  test('cancellation while awaiting credentials does not start Rust sync', () async {
    final api = _SyncApi();
    RustLib.initMock(api: api);
    addTearDown(RustLib.dispose);
    final repository = _PendingCredentialsRepo();
    final adapter = SyncLibraryFrbAdapter(libraryRepository: repository);
    var cancelled = false;
    final progress = <SyncLibraryProgress>[];
    final run = adapter.call(
      isCancelled: () => cancelled,
      onProgress: progress.add,
    );
    await repository.passwordRequested.future;
    cancelled = true;
    adapter.cancelActive();
    repository.password.complete('secret');
    // Closing the potential stream lets the original implementation finish too.
    for (final stream in api.streams.values) {
      unawaited(stream.close());
    }
    await run;
    final cancelledBeforeIdle = List<rust.SyncHandleDto>.of(api.cancelled);
    adapter.cancelActive();
    expect(api.started, isEmpty);
    expect(progress, isEmpty);
    expect(cancelledBeforeIdle, isNotEmpty);
    expect(cancelledBeforeIdle, everyElement(same(api.created.single)));
    expect(api.cancelled, cancelledBeforeIdle);
  });

  test(
    'loadRemoteCredentialsForSync only includes target remote when not syncAll',
    () async {
      final creds = await loadRemoteCredentialsForSync(
        libraryRepository: _CredRepo(
          libraries: <LocalLibrary>[
            _lib(id: 'local1', kind: 'local'),
            _lib(id: 'remote1', kind: 'remote'),
            _lib(id: 'remote2', kind: 'remote'),
          ],
          passwords: <String, String?>{
            'remote1': 'secret1',
            'remote2': 'secret2',
          },
        ),
        syncAll: false,
        targetLibraryId: 'remote1',
      );

      expect(creds, hasLength(1));
      expect(creds.single.libraryId, 'remote1');
      expect(creds.single.password, 'secret1');
    },
  );

  test('loadRemoteCredentialsForSync includes all remotes with passwords when syncAll', () async {
    final creds = await loadRemoteCredentialsForSync(
      libraryRepository: _CredRepo(
        libraries: <LocalLibrary>[
          _lib(id: 'remote1', kind: 'remote'),
          _lib(id: 'remote2', kind: 'remote'),
        ],
        passwords: <String, String?>{'remote1': 'secret1', 'remote2': null},
      ),
      syncAll: true,
    );

    expect(creds, hasLength(1));
    expect(creds.single.libraryId, 'remote1');
  });

  test('mapRustSyncProgress maps migrated count on done', () {
    const rust.SyncLibraryProgressDto dto = rust.SyncLibraryProgressDto(
      phase: rust.SyncLibraryPhaseDto.done,
      route: rust.SyncLibraryRouteDto.withRoots,
      acceptedTotal: 1,
      counts: rust.LibrarySyncCountsDto(
        dir: 0,
        zip: 0,
        cbz: 1,
        epub: 0,
        cbr: 0,
        rar: 0,
        cb7: 0,
        sevenz: 0,
        pdf: 0,
      ),
      removedCount: 0,
      addedCount: 0,
      keptCount: 0,
      migratedCount: 1,
    );

    final SyncLibraryProgress mapped = mapRustSyncProgress(dto);

    expect(mapped.phase, SyncLibraryPhase.done);
    expect(mapped.migratedCount, 1);
  });

  test('mapRustSyncProgress maps failed phase and error message', () {
    const rust.SyncLibraryProgressDto dto = rust.SyncLibraryProgressDto(
      phase: rust.SyncLibraryPhaseDto.failed,
      route: rust.SyncLibraryRouteDto.withRoots,
      acceptedTotal: 0,
      counts: rust.LibrarySyncCountsDto(
        dir: 0,
        zip: 0,
        cbz: 0,
        epub: 0,
        cbr: 0,
        rar: 0,
        cb7: 0,
        sevenz: 0,
        pdf: 0,
      ),
      errorMessage: 'db failed',
    );

    final SyncLibraryProgress mapped = mapRustSyncProgress(dto);

    expect(mapped.phase, SyncLibraryPhase.failed);
    expect(mapped.errorMessage, 'db failed');
  });

  test('failed progress throws LibrarySyncException in adapter flow', () {
    expect(
      () => throw LibrarySyncException('db failed'),
      throwsA(
        isA<LibrarySyncException>().having(
          (LibrarySyncException e) => e.message,
          'message',
          'db failed',
        ),
      ),
    );
  });
}
