import 'dart:async';

import 'package:hentai_library/features/library_admin/application/library_migration_store.dart';
import 'package:test/test.dart';
import 'package:hentai_library/features/library_admin/application/load_libraries_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';

class _Repository implements LibraryRepository {
  final calls = <String>[];
  bool fail = false;
  String? failUpdateFor;
  List<LocalLibrary> libraries = [];
  final savedFormats = <String>[];
  final formats = <String, List<ResourceFormatCategory>>{};
  Completer<List<LocalLibrary>>? initialList;
  final queuedLists = <Future<List<LocalLibrary>>>[];
  @override
  Future<List<LocalLibrary>> list() async {
    calls.add('list');
    if (calls.length == 1 && initialList != null) return initialList!.future;
    if (queuedLists.isNotEmpty) return queuedLists.removeAt(0);
    if (fail) throw StateError('list');
    return libraries;
  }

  @override
  Future<LocalLibrary> updateResourceFormatCategories({
    required String libraryId,
    required List<ResourceFormatCategory> groups,
  }) async {
    if (libraryId == failUpdateFor) throw StateError('update');
    savedFormats.add(libraryId);
    formats[libraryId] = List.of(groups);
    return libraries.firstWhere((library) => library.libraryId == libraryId);
  }

  @override
  Future<void> setAllScanOnStartup(bool enabled) async {
    calls.add('scan:$enabled');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final migration in LibraryPreferenceMigration.values) {
    test(
      'checkpoint failure preserves staged input until explicit retry: $migration',
      () async {
        final repo = _Repository()..libraries = [_library('one')];
        final migrations = _Migrations()..failMark = migration;
        var clears = 0;
        final useCase = LoadLibrariesUseCase(
          repository: repo,
          migrations: migrations,
          peekLegacyResourceFormatPayload: () async =>
              (enabledFormatGroups: ['pdf']),
          peekLegacyAutoScan: () async => true,
          clearLegacyImportPayload: () async {
            clears++;
          },
        );
        await useCase();
        expect(clears, 0);
        expect(migrations.completed, isNot(contains(migration)));
        migrations.failMark = null;
        await useCase();
        expect(clears, 1);
        expect(migrations.completed, LibraryPreferenceMigration.values.toSet());
      },
    );
  }

  test(
    'overlapping loads share initialization before reading independent lists',
    () async {
      final repo = _Repository()
        ..libraries = [_library('one')]
        ..initialList = Completer<List<LocalLibrary>>();
      final migrations = _Migrations();
      ({Object? enabledFormatGroups})? staged = (enabledFormatGroups: ['pdf']);
      var clears = 0;
      final useCase = LoadLibrariesUseCase(
        repository: repo,
        migrations: migrations,
        peekLegacyResourceFormatPayload: () async => staged,
        peekLegacyAutoScan: () async => true,
        clearLegacyImportPayload: () async {
          clears++;
          staged = null;
        },
      );
      final first = useCase();
      await Future<void>.delayed(Duration.zero);
      final second = useCase();
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, ['list']);
      expect(clears, 0);
      repo.initialList!.complete(repo.libraries);
      await Future.wait([first, second]);
      expect(repo.savedFormats, ['one']);
      expect(repo.formats['one'], [ResourceFormatCategory.pdf]);
      expect(repo.calls, ['list', 'scan:true', 'list', 'list']);
      expect(clears, 1);
      expect(staged, isNull);
    },
  );

  test(
    'partial migration retains the staged source for an explicit retry',
    () async {
      final repo = _Repository()
        ..libraries = [_library('first'), _library('second')]
        ..failUpdateFor = 'second';
      final migrations = _Migrations();
      ({Object? enabledFormatGroups})? staged = (enabledFormatGroups: ['pdf']);
      final useCase = LoadLibrariesUseCase(
        repository: repo,
        migrations: migrations,
        peekLegacyResourceFormatPayload: () async => staged,
        peekLegacyAutoScan: () async => false,
        clearLegacyImportPayload: () async => staged = null,
      );
      await useCase();
      expect(staged, isNotNull);
      expect(migrations.completed, {LibraryPreferenceMigration.autoScan});
      repo.failUpdateFor = null;
      await useCase();
      expect(repo.formats.values, everyElement([ResourceFormatCategory.pdf]));
      expect(migrations.completed, LibraryPreferenceMigration.values.toSet());
      expect(staged, isNull);
    },
  );

  test('shared preparation does not share list values or errors', () async {
    final repo = _Repository();
    final migrations = _Migrations()
      ..completed.addAll(LibraryPreferenceMigration.values);
    final firstList = Completer<List<LocalLibrary>>();
    final secondList = Completer<List<LocalLibrary>>();
    repo.queuedLists.addAll([firstList.future, secondList.future]);
    var clears = 0;
    final useCase = LoadLibrariesUseCase(
      repository: repo,
      migrations: migrations,
      peekLegacyResourceFormatPayload: () async => null,
      peekLegacyAutoScan: () async => null,
      clearLegacyImportPayload: () async {
        clears++;
      },
    );
    final first = useCase();
    final error = StateError('first list');
    final checked = expectLater(first, throwsA(same(error)));
    final second = useCase();
    await Future<void>.delayed(Duration.zero);
    secondList.complete([_library('second')]);
    firstList.completeError(error);
    expect((await second).libraries.single.libraryId, 'second');
    await checked;
    expect(clears, 1);
    repo.libraries = [_library('later')];
    expect((await useCase()).libraries.single.libraryId, 'later');
    expect(clears, 2);
  });

  test(
    'cleanup failure is best effort and can be retried explicitly',
    () async {
      final repo = _Repository();
      final migrations = _Migrations()
        ..completed.addAll(LibraryPreferenceMigration.values);
      var clears = 0;
      final useCase = LoadLibrariesUseCase(
        repository: repo,
        migrations: migrations,
        peekLegacyResourceFormatPayload: () async => null,
        peekLegacyAutoScan: () async => null,
        clearLegacyImportPayload: () async {
          if (++clears == 1) throw StateError('cleanup');
        },
      );
      await useCase();
      await useCase();
      expect(clears, 2);
      expect(repo.calls, ['list', 'list']);
    },
  );

  test(
    'a reentrant load shares initialization and retains its own list read',
    () async {
      final repo = _Repository()..libraries = [_library('one')];
      final migrations = _Migrations();
      late LoadLibrariesUseCase useCase;
      Future<LibrariesState>? reentrant;
      migrations.onCheck = () {
        reentrant ??= useCase();
      };
      useCase = LoadLibrariesUseCase(
        repository: repo,
        migrations: migrations,
        peekLegacyResourceFormatPayload: () async =>
            (enabledFormatGroups: ['pdf']),
        peekLegacyAutoScan: () async => false,
        clearLegacyImportPayload: () async {},
      );
      await useCase();
      await reentrant;
      expect(repo.savedFormats, ['one']);
      expect(repo.calls, ['list', 'list', 'list']);
    },
  );

  test('partial migration retains successful writes and marks completion only after every library', () async {
    final repo = _Repository()
      ..libraries = [_library('first'), _library('second')]
      ..failUpdateFor = 'second';
    final migrations = _Migrations();
    final useCase = LoadLibrariesUseCase(
      repository: repo,
      migrations: migrations,
      peekLegacyResourceFormatPayload: () async =>
          (enabledFormatGroups: ['pdf']),
      peekLegacyAutoScan: () async => false,
      clearLegacyImportPayload: () async {
        repo.calls.add('clear');
      },
    );
    expect((await useCase()).libraries, hasLength(2));
    expect(repo.savedFormats, ['first']);
    expect(migrations.completed, {LibraryPreferenceMigration.autoScan});
    expect(repo.calls, ['list', 'list']);
    repo.failUpdateFor = null;
    await useCase();
    expect(repo.savedFormats, ['first', 'first', 'second']);
    expect(migrations.completed, LibraryPreferenceMigration.values.toSet());
    repo.savedFormats.clear();
    await useCase();
    expect(repo.savedFormats, isEmpty);
  });

  test('empty libraries mark both migrations, cleanup precedes final read and reload skips migration', () async {
    final repo = _Repository();
    final migrations = _Migrations();
    var peeks = 0;
    final useCase = LoadLibrariesUseCase(
      repository: repo,
      migrations: migrations,
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
    expect(migrations.completed, {
      LibraryPreferenceMigration.resourceFormats,
      LibraryPreferenceMigration.autoScan,
    });
    expect(peeks, 0);
    repo.calls.clear();
    await useCase();
    expect(repo.calls, ['clear', 'list']);
  });
  test('migration and cleanup failures are best effort but final read failure propagates', () async {
    final repo = _Repository();
    final useCase = LoadLibrariesUseCase(
      repository: repo,
      migrations: _Migrations()..fail = true,
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

LocalLibrary _library(String id) => (
  libraryId: id,
  kind: 'local',
  rootPath: '/books',
  name: id,
  enabledResourceFormatCategories: ResourceFormatCategory.all,
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: true,
  sidebarOrder: 0,
);

class _Migrations implements LibraryMigrationStore {
  final completed = <LibraryPreferenceMigration>{};
  bool fail = false;
  LibraryPreferenceMigration? failMark;
  void Function()? onCheck;
  @override
  Future<bool> isCompleted(LibraryPreferenceMigration migration) async {
    final check = onCheck;
    onCheck = null;
    check?.call();
    if (fail) throw StateError('flag');
    return completed.contains(migration);
  }

  @override
  Future<void> markCompleted(LibraryPreferenceMigration migration) async {
    if (migration == failMark) throw StateError('checkpoint');
    completed.add(migration);
  }
}
