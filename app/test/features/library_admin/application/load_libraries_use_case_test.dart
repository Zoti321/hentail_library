import 'package:test/test.dart';
import 'package:hentai_library/features/library_admin/application/load_libraries_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';

class _Repository implements LibraryRepository {
  final calls = <String>[];
  bool fail = false;
  @override
  Future<List<LocalLibrary>> list() async {
    calls.add('list');
    if (fail) throw StateError('list');
    return [];
  }

  @override
  Future<void> setAllScanOnStartup(bool enabled) async {
    calls.add('scan:$enabled');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('empty libraries mark both migrations, cleanup precedes final read and reload skips migration', () async {
    final repo = _Repository();
    final flags = <String, bool>{};
    var peeks = 0;
    final useCase = LoadLibrariesUseCase(
      repository: repo,
      readFlag: (key) async => flags[key],
      writeFlag: (key, value) async {
        flags[key] = value;
      },
      peekLegacyResourceFormatPayload: () async {
        peeks++;
        return null;
      },
      peekLegacyAutoScan: () async => true,
      clearLegacyImportPayload: () async {
        repo.calls.add('clear');
      },
    );
    expect((await useCase()).libraries, isEmpty);
    expect(repo.calls, ['list', 'scan:true', 'clear', 'list']);
    expect(flags.values, [true, true]);
    expect(peeks, 0);
    repo.calls.clear();
    await useCase();
    expect(repo.calls, ['clear', 'list']);
  });
  test('migration and cleanup failures are best effort but final read failure propagates', () async {
    final repo = _Repository();
    final useCase = LoadLibrariesUseCase(
      repository: repo,
      readFlag: (_) async => throw StateError('flag'),
      writeFlag: (_, value) async {},
      peekLegacyResourceFormatPayload: () async => null,
      peekLegacyAutoScan: () async => null,
      clearLegacyImportPayload: () async => throw StateError('clear'),
    );
    expect((await useCase()).libraries, isEmpty);
    repo.fail = true;
    await expectLater(useCase(), throwsStateError);
    expect(repo.calls, ['list', 'list']);
  });
}
