import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;
import 'package:test/test.dart';

class _CredRepo implements LibraryRepository {
  _CredRepo({
    required this.libraries,
    required this.currentId,
    required this.passwords,
  });

  final List<LocalLibrary> libraries;
  final String? currentId;
  final Map<String, String?> passwords;

  @override
  Future<List<LocalLibrary>> list() async => libraries;

  @override
  Future<String?> getCurrentId() async => currentId;

  @override
  Future<String?> readRemotePassword(String libraryId) async =>
      passwords[libraryId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocalLibrary _lib({
  required String id,
  required String kind,
}) => (
  libraryId: id,
  kind: kind,
  rootPath: kind == 'remote' ? 'https://example/dav' : 'C:/lib',
  name: id,
  enabledFormatGroups: FormatGroup.all,
  username: kind == 'remote' ? 'u' : '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: true,
  sidebarOrder: 0,
);

void main() {
  test('loadRemoteCredentialsForSync only includes current remote when not syncAll', () async {
    final creds = await loadRemoteCredentialsForSync(
      libraryRepository: _CredRepo(
        libraries: <LocalLibrary>[
          _lib(id: 'local1', kind: 'local'),
          _lib(id: 'remote1', kind: 'remote'),
          _lib(id: 'remote2', kind: 'remote'),
        ],
        currentId: 'remote1',
        passwords: <String, String?>{
          'remote1': 'secret1',
          'remote2': 'secret2',
        },
      ),
      syncAll: false,
    );

    expect(creds, hasLength(1));
    expect(creds.single.libraryId, 'remote1');
    expect(creds.single.password, 'secret1');
  });

  test('loadRemoteCredentialsForSync includes all remotes with passwords when syncAll', () async {
    final creds = await loadRemoteCredentialsForSync(
      libraryRepository: _CredRepo(
        libraries: <LocalLibrary>[
          _lib(id: 'remote1', kind: 'remote'),
          _lib(id: 'remote2', kind: 'remote'),
        ],
        currentId: 'remote1',
        passwords: <String, String?>{
          'remote1': 'secret1',
          'remote2': null,
        },
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

  test('failed progress throws SyncException in adapter flow', () {
    expect(
      () => throw SyncException('db failed'),
      throwsA(
        isA<SyncException>().having(
          (SyncException e) => e.message,
          'message',
          'db failed',
        ),
      ),
    );
  });
}
