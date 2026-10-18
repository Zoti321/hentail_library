import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/di/shared_state_ports.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/current_library_port.dart';
import 'package:hentai_library/shared/domain/library/format_group.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/shared/domain/repositories/library_repository.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [CurrentLibraryPort] 契约测：经真实 `createCurrentLibraryPort` 适配器驱动，
/// 仓库侧删库回落语义与 `core/.../library/crud.rs::delete_library` 对齐（删当前库 → 剩余首个或 null）。
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
  _FakeLibraryRepository(this.libraries, {String? currentId})
    : _currentId = currentId;

  final List<LocalLibrary> libraries;
  String? _currentId;
  bool failNextDelete = false;

  @override
  Future<List<LocalLibrary>> list() async => List<LocalLibrary>.from(libraries);

  @override
  Future<String?> getCurrentId() async => _currentId;

  @override
  Future<void> setCurrentId(String? libraryId) async {
    _currentId = libraryId;
  }

  @override
  Future<void> delete(String libraryId) async {
    if (failNextDelete) {
      failNextDelete = false;
      throw Exception('delete failed');
    }
    libraries.removeWhere((LocalLibrary l) => l.libraryId == libraryId);
    if (_currentId == libraryId) {
      _currentId = libraries.isEmpty ? null : libraries.first.libraryId;
    }
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
    ], currentId: 'lib-a');
    container = ProviderContainer(
      overrides: <Override>[
        libraryRepoProvider.overrideWithValue(repo),
        libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
        currentLibraryPortProvider.overrideWith(createCurrentLibraryPort),
      ],
    );
  });

  tearDown(() => container.dispose());

  CurrentLibraryPort port() => container.read(currentLibraryPortProvider);

  Future<List<String>> libraryIds() async => (await container.read(
    currentLibraryProvider.future,
  )).libraries.map((LocalLibrary l) => l.libraryId).toList();

  test('currentId reflects the repository current selection', () async {
    await container.read(currentLibraryProvider.future);

    expect(await port().currentId(), 'lib-a');
  });

  test('select persists the new current id and bumps revision', () async {
    await container.read(currentLibraryProvider.future);
    final int revisionBefore = container.read(libraryRevisionProvider).revision;

    await port().select('lib-b');

    expect(await port().currentId(), 'lib-b');
    expect(repo._currentId, 'lib-b');
    expect(
      container.read(libraryRevisionProvider).revision,
      greaterThan(revisionBefore),
    );
  });

  test('clear removes the current id', () async {
    await container.read(currentLibraryProvider.future);

    await port().clear();

    expect(await port().currentId(), isNull);
  });

  test(
    'deleting the current library falls back to the first remaining one',
    () async {
      await container.read(currentLibraryProvider.future);
      await port().select('lib-b');
      final int revisionBefore = container
          .read(libraryRevisionProvider)
          .revision;

      await port().deleteLibrary('lib-b');

      expect(await libraryIds(), <String>['lib-a']);
      expect(await port().currentId(), 'lib-a');
      expect(
        container.read(libraryRevisionProvider).revision,
        greaterThan(revisionBefore),
      );
    },
  );

  test('deleting the last library clears current', () async {
    await container.read(currentLibraryProvider.future);
    await port().deleteLibrary('lib-b');

    await port().deleteLibrary('lib-a');

    expect(await libraryIds(), isEmpty);
    expect(await port().currentId(), isNull);
  });

  test('deleteLibrary failure rethrows and keeps state and revision', () async {
    await container.read(currentLibraryProvider.future);
    final int revisionBefore = container.read(libraryRevisionProvider).revision;
    repo.failNextDelete = true;

    await expectLater(port().deleteLibrary('lib-a'), throwsException);

    expect(await libraryIds(), <String>['lib-a', 'lib-b']);
    expect(await port().currentId(), 'lib-a');
    expect(container.read(libraryRevisionProvider).revision, revisionBefore);
  });

  test('submitLibraryForm invalid returns error without writing', () async {
    await container.read(currentLibraryProvider.future);
    final int revisionBefore = container.read(libraryRevisionProvider).revision;

    final LibraryFormApplyResult result = await port().submitLibraryForm(
      LibraryForm.createLocal(),
    );

    expect(result, isA<LibraryFormApplyInvalid>());
    expect(await libraryIds(), <String>['lib-a', 'lib-b']);
    expect(container.read(libraryRevisionProvider).revision, revisionBefore);
  });

  test(
    'submitLibraryForm create reloads libraries and bumps revision',
    () async {
      await container.read(currentLibraryProvider.future);
      final int revisionBefore = container
          .read(libraryRevisionProvider)
          .revision;

      final LibraryFormApplyResult result = await port().submitLibraryForm(
        LibraryForm.createLocal().copyWith(rootPath: '/lib-c', name: 'C'),
      );

      expect(result, isA<LibraryFormApplySucceeded>());
      expect(await libraryIds(), <String>['lib-a', 'lib-b', 'lib-c']);
      expect(
        container.read(libraryRevisionProvider).revision,
        greaterThan(revisionBefore),
      );
    },
  );
}
