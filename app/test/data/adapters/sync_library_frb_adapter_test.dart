import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;
import 'package:test/test.dart';

void main() {
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
      errorMessage: '数据库操作失败',
    );

    final SyncLibraryProgress mapped = mapRustSyncProgress(dto);

    expect(mapped.phase, SyncLibraryPhase.failed);
    expect(mapped.errorMessage, '数据库操作失败');
  });

  test('failed progress throws SyncException in adapter flow', () {
    expect(
      () => throw SyncException('数据库操作失败'),
      throwsA(
        isA<SyncException>().having(
          (SyncException e) => e.message,
          'message',
          '数据库操作失败',
        ),
      ),
    );
  });
}
