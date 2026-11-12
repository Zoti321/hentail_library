import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:hentai_library/features/metadata_backup/application/run_metadata_auto_backup_use_case.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';

class _Repository implements MetadataBackupRepository {
  var exports = 0;
  bool fail = false;
  @override
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  }) {
    exports++;
    if (fail) throw StateError('export');
    return Uint8List.fromList([1]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Files implements MetadataBackupFileGateway {
  final calls = <String>[];
  Completer<void>? hold;
  @override
  Future<String> prepareBackupDirectory() async {
    calls.add('directory');
    await hold?.future;
    return '/isolated';
  }

  @override
  String backupPath(String directory, String name) => '$directory/$name';
  @override
  Future<List<int>> compress(Uint8List bytes) async {
    calls.add('compress');
    return bytes;
  }

  @override
  Future<void> write(String path, List<int> bytes) async {
    calls.add('write:$path');
  }

  @override
  void prune(String directory, {required int maxFiles}) {
    calls.add('prune:$maxFiles');
  }

  @override
  Future<Uint8List> decode(List<int> bytes, String path) async =>
      Uint8List.fromList(bytes);
}

void main() {
  test(
    'concurrent trigger is ignored, records only after write and keeps three',
    () async {
      final repo = _Repository();
      final files = _Files()..hold = Completer<void>();
      final recorded = <DateTime>[];
      final at = DateTime(2026, 11, 12, 10);
      final useCase = RunMetadataAutoBackupUseCase(
        repository: repo,
        files: files,
        recordCompletion: (date) async {
          expect(files.calls.last, 'prune:3');
          recorded.add(date);
        },
      );
      final first = useCase(enabled: true, fromStartup: false, now: () => at);
      await useCase(enabled: true, fromStartup: false);
      files.hold!.complete();
      await first;
      expect(repo.exports, 1);
      expect(recorded, [at]);
      expect(files.calls.where((e) => e.startsWith('write:')), hasLength(1));
    },
  );
  test('failure records nothing and releases concurrency guard', () async {
    final repo = _Repository()..fail = true;
    final files = _Files();
    var recorded = 0;
    final useCase = RunMetadataAutoBackupUseCase(
      repository: repo,
      files: files,
      recordCompletion: (_) async {
        recorded++;
      },
    );
    await expectLater(
      useCase(enabled: true, fromStartup: false),
      throwsStateError,
    );
    expect(recorded, 0);
    expect(files.calls, ['directory']);
    repo.fail = false;
    await useCase(enabled: true, fromStartup: false);
    expect(recorded, 1);
  });
  test('startup interval, disabled and force retain original rules', () async {
    final repo = _Repository();
    final files = _Files();
    final at = DateTime(2026, 11, 12);
    final useCase = RunMetadataAutoBackupUseCase(
      repository: repo,
      files: files,
      recordCompletion: (_) async {},
    );
    await useCase(enabled: false, fromStartup: false);
    await useCase(
      enabled: true,
      fromStartup: true,
      lastBackupAt: at,
      now: () => at,
    );
    expect(repo.exports, 0);
    await useCase(
      enabled: false,
      fromStartup: true,
      force: true,
      lastBackupAt: at,
      now: () => at,
    );
    expect(repo.exports, 1);
  });
}
