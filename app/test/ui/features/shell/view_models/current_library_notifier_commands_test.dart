import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/value_objects/form/library_form.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

LocalLibrary _library(String id) {
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

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this.libraries);

  final List<LocalLibrary> libraries;
  final List<String> deletedIds = <String>[];
  bool failNextDelete = false;

  @override
  Future<List<LocalLibrary>> list() async => List<LocalLibrary>.from(libraries);

  @override
  Future<String?> getCurrentId() async => null;

  @override
  Future<void> delete(String libraryId) async {
    if (failNextDelete) {
      failNextDelete = false;
      throw Exception('delete failed');
    }
    deletedIds.add(libraryId);
    libraries.removeWhere((LocalLibrary l) => l.libraryId == libraryId);
  }

  @override
  Future<LocalLibrary> createLocal(String rootPath, {String? name}) async {
    final LocalLibrary created = _library(rootPath.substring(1));
    libraries.add(created);
    return created;
  }

  @override
  Future<LocalLibrary> updateSettings({
    required String libraryId,
    required String name,
    required List<FormatGroup> groups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) async {
    return libraries.firstWhere((LocalLibrary l) => l.libraryId == libraryId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentRevisionPort implements LibraryRevisionPort {
  @override
  Stream<void> watchRevision() => const Stream<void>.empty();
}

void main() {
  late _FakeLibraryRepository repo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'migrated_enabled_format_groups_to_libraries_v1': true,
      'migrated_auto_scan_to_libraries_v1': true,
    });
    repo = _FakeLibraryRepository(<LocalLibrary>[
      _library('lib-a'),
      _library('lib-b'),
    ]);
    container = ProviderContainer(
      overrides: <Override>[
        libraryRepoProvider.overrideWithValue(repo),
        libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
      ],
    );
  });

  tearDown(() => container.dispose());

  List<String> libraryIds() => container
      .read(currentLibraryProvider)
      .requireValue
      .libraries
      .map((LocalLibrary l) => l.libraryId)
      .toList();

  test('deleteLibrary deletes, reloads libraries and bumps revision', () async {
    await container.read(currentLibraryProvider.future);
    final int revisionBefore = container.read(libraryRevisionProvider).revision;

    await container
        .read(currentLibraryProvider.notifier)
        .deleteLibrary('lib-a');

    expect(repo.deletedIds, <String>['lib-a']);
    expect(libraryIds(), <String>['lib-b']);
    expect(
      container.read(libraryRevisionProvider).revision,
      greaterThan(revisionBefore),
    );
  });

  test('submitLibraryForm returns validation errors without writing', () async {
    await container.read(currentLibraryProvider.future);
    final int revisionBefore = container.read(libraryRevisionProvider).revision;

    final LibraryFormApplyResult result = await container
        .read(currentLibraryProvider.notifier)
        .submitLibraryForm(LibraryForm.createLocal());

    expect(result, isA<LibraryFormApplyInvalid>());
    expect(libraryIds(), <String>['lib-a', 'lib-b']);
    expect(container.read(libraryRevisionProvider).revision, revisionBefore);
  });

  test(
    'submitLibraryForm creates, reloads libraries and bumps revision',
    () async {
      await container.read(currentLibraryProvider.future);
      final int revisionBefore = container
          .read(libraryRevisionProvider)
          .revision;

      final LibraryFormApplyResult result = await container
          .read(currentLibraryProvider.notifier)
          .submitLibraryForm(
            LibraryForm.createLocal().copyWith(rootPath: '/lib-c', name: 'C'),
          );

      expect(result, isA<LibraryFormApplySucceeded>());
      expect(libraryIds(), <String>['lib-a', 'lib-b', 'lib-c']);
      expect(
        container.read(libraryRevisionProvider).revision,
        greaterThan(revisionBefore),
      );
    },
  );

  test('deleteLibrary failure rethrows and keeps libraries', () async {
    await container.read(currentLibraryProvider.future);
    repo.failNextDelete = true;

    await expectLater(
      container.read(currentLibraryProvider.notifier).deleteLibrary('lib-a'),
      throwsException,
    );
    expect(libraryIds(), <String>['lib-a', 'lib-b']);
  });
}
