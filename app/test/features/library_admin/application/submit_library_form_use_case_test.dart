import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/library_admin/application/submit_library_form_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:test/test.dart';

class _RecordingLibraryRepository implements LibraryRepository {
  final List<String> calls = <String>[];
  bool failSettings = false;
  String? lastName;
  String? lastRoot;
  String? lastPassword;
  List<ResourceFormatCategory>? lastGroups;
  bool? lastScanOnStartup;
  ScanInterval? lastScanInterval;

  @override
  Future<LocalLibrary> createLocal(String rootPath, {String? name}) async {
    calls.add('createLocal');
    lastRoot = rootPath;
    lastName = name;
    return _lib(kind: 'local', root: rootPath, name: name ?? 'derived');
  }

  @override
  Future<LocalLibrary> createImageSetLocal(
    String rootPath, {
    String? name,
  }) async {
    calls.add('createImageSetLocal');
    lastRoot = rootPath;
    lastName = name;
    return _lib(
      kind: 'local',
      catalogKind: 'image_set',
      root: rootPath,
      name: name ?? 'derived',
      groups: const <ResourceFormatCategory>[],
    );
  }

  @override
  Future<LocalLibrary> createRemote({
    required String rootUrl,
    required String username,
    required String password,
    required bool allowHttp,
    String? name,
  }) async {
    calls.add('createRemote');
    lastRoot = rootUrl;
    lastName = name;
    lastPassword = password;
    return _lib(
      kind: 'remote',
      catalogKind: 'comic',
      root: rootUrl,
      name: name ?? 'derived',
      username: username,
      allowHttp: allowHttp,
    );
  }

  @override
  Future<LocalLibrary> updateLocalRoot({
    required String libraryId,
    required String rootPath,
  }) async {
    calls.add('updateLocalRoot');
    lastRoot = rootPath;
    return _lib(kind: 'local', root: rootPath, name: lastName ?? 'Alpha');
  }

  @override
  Future<LocalLibrary> updateRemote({
    required String libraryId,
    required String rootUrl,
    required String username,
    required bool allowHttp,
    String? password,
  }) async {
    calls.add('updateRemote');
    lastRoot = rootUrl;
    lastPassword = password;
    return _lib(
      kind: 'remote',
      catalogKind: 'comic',
      root: rootUrl,
      name: lastName ?? 'Remote',
      username: username,
      allowHttp: allowHttp,
    );
  }

  @override
  Future<LocalLibrary> updateSettings({
    required String libraryId,
    required String name,
    required List<ResourceFormatCategory> groups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) async {
    calls.add('updateSettings');
    if (failSettings) throw StateError('settings');
    lastName = name;
    lastGroups = groups;
    lastScanOnStartup = scanOnStartup;
    lastScanInterval = scanInterval;
    return _lib(kind: 'local', root: lastRoot ?? '/r', name: name);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocalLibrary _lib({
  required String kind,
  String catalogKind = 'comic',
  required String root,
  required String name,
  String username = '',
  bool allowHttp = false,
  List<ResourceFormatCategory>? groups,
  bool scanOnStartup = false,
  ScanInterval scanInterval = ScanInterval.disabled,
}) {
  return (
    libraryId: 'lib-1',
    kind: kind,
    catalogKind: catalogKind,
    rootPath: root,
    name: name,
    enabledResourceFormatCategories:
        groups ??
        (kind == 'remote'
            ? <ResourceFormatCategory>[
                ResourceFormatCategory.pdf,
                ResourceFormatCategory.epub,
                ResourceFormatCategory.archive,
              ]
            : ResourceFormatCategory.all),
    username: username,
    allowHttp: allowHttp,
    scanOnStartup: scanOnStartup,
    scanInterval: scanInterval,
    pinned: true,
    sidebarOrder: 0,
  );
}

void main() {
  test('invalid submit writes and publishes nothing', () async {
    final repo = _RecordingLibraryRepository();
    final events = _Events();
    final result = await SubmitLibraryFormUseCase(repo, events)(
      LibraryForm.createLocal(),
    );
    expect(result, isA<LibraryFormApplyInvalid>());
    expect(repo.calls, isEmpty);
    expect(events.events, isEmpty);
  });
  test(
    'settings failure preserves creation without retry or success event',
    () async {
      final repo = _RecordingLibraryRepository()..failSettings = true;
      final events = _Events();
      await expectLater(
        SubmitLibraryFormUseCase(repo, events)(
          LibraryForm.createLocal().copyWith(
            name: 'A',
            rootPath: '/r',
            scanOnStartup: true,
          ),
        ),
        throwsStateError,
      );
      expect(repo.calls, ['createLocal', 'updateSettings']);
      expect(events.events, isEmpty);
    },
  );
  test('unchanged submit retains one completion fact', () async {
    final repo = _RecordingLibraryRepository();
    final events = _Events();
    final original = _lib(kind: 'local', root: '/r', name: 'A');
    await SubmitLibraryFormUseCase(repo, events)(
      LibraryForm.fromLibrary(original),
      original: original,
    );
    expect(repo.calls, isEmpty);
    expect(events.events, [isA<LibraryCatalogChanged>()]);
  });

  group('SubmitLibraryFormUseCase.create', () {
    test('local create then settings when scan differs', () async {
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.createLocal()
          .copyWith(name: 'Alpha', rootPath: r'D:\comics', scanOnStartup: true)
          .submit(repo);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect(repo.calls, <String>['createLocal', 'updateSettings']);
      expect(repo.lastScanOnStartup, isTrue);
    });

    test('remote create with defaults skips settings write', () async {
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.createRemote()
          .copyWith(
            name: 'Nas',
            rootPath: 'https://dav.example/c',
            password: 'secret',
          )
          .submit(repo);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect(repo.calls, <String>['createRemote']);
    });
  });

  group('SubmitLibraryFormUseCase.edit', () {
    test('no-op when unchanged', () async {
      final LocalLibrary original = _lib(
        kind: 'local',
        catalogKind: 'comic',
        root: r'D:\comics',
        name: 'Alpha',
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.fromLibrary(
        original,
      ).submit(repo, original: original);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect(repo.calls, isEmpty);
    });

    test('image set root change is ignored without updateLocalRoot', () async {
      final LocalLibrary original = _lib(
        kind: 'local',
        catalogKind: 'image_set',
        root: r'D:\images',
        name: 'Alpha',
        groups: const <ResourceFormatCategory>[],
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result =
          await LibraryForm.fromLibrary(original)
              .copyWith(rootPath: r'D:\images2', name: 'Beta')
              .submit(repo, original: original);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect((result as LibraryFormApplySucceeded).rootChanged, isFalse);
      expect(repo.calls, <String>['updateSettings']);
      expect(repo.lastName, 'Beta');
    });

    test(
      'image set edit keeps Local-only and root lock but allows scan settings',
      () async {
        final original = _lib(
          kind: 'local',
          catalogKind: 'image_set',
          root: r'D:\images',
          name: 'Alpha',
          groups: const <ResourceFormatCategory>[],
        );
        final repo = _RecordingLibraryRepository();
        final events = _Events();
        final result = await SubmitLibraryFormUseCase(repo, events)(
          LibraryForm.createRemote().copyWith(
            name: 'Beta',
            rootPath: 'https://example.com/dav',
            password: 'secret',
            scanOnStartup: true,
            scanInterval: ScanInterval.daily,
          ),
          original: original,
        );

        expect(result, isA<LibraryFormApplySucceeded>());
        expect((result as LibraryFormApplySucceeded).rootChanged, isFalse);
        expect(repo.calls, ['updateSettings']);
        expect(repo.lastName, 'Beta');
        expect(repo.lastGroups, isEmpty);
        expect(repo.lastScanOnStartup, isTrue);
        expect(repo.lastScanInterval, ScanInterval.daily);
        expect(events.events, [isA<LibraryCatalogChanged>()]);
      },
    );

    test(
      'comic edit retains root migration despite an image set draft',
      () async {
        final original = _lib(kind: 'local', root: '/old', name: 'Alpha');
        final repo = _RecordingLibraryRepository();
        final result = await LibraryForm.fromLibrary(original)
            .copyWith(isImageSet: true, rootPath: '/new')
            .submit(repo, original: original);

        expect(result, isA<LibraryFormApplySucceeded>());
        expect((result as LibraryFormApplySucceeded).rootChanged, isTrue);
        expect(repo.calls, ['updateLocalRoot']);
        expect(repo.lastRoot, '/new');
      },
    );

    test(
      'remote edit keeps its connection command despite a local draft',
      () async {
        final original = _lib(
          kind: 'remote',
          root: 'https://example.com/old',
          name: 'Alpha',
        );
        final repo = _RecordingLibraryRepository();
        await LibraryForm.fromLibrary(original)
            .copyWith(isRemote: false, rootPath: 'https://example.com/new')
            .submit(repo, original: original);

        expect(repo.calls, ['updateRemote']);
        expect(repo.lastRoot, 'https://example.com/new');
        expect(repo.lastPassword, isNull);
      },
    );

    test(
      'image set create writes scan settings when they differ from defaults',
      () async {
        final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
        final LibraryFormApplyResult result =
            await LibraryForm.createImageSetLocal()
                .copyWith(
                  name: 'Gallery',
                  rootPath: r'D:\images',
                  scanOnStartup: true,
                  scanInterval: ScanInterval.daily,
                )
                .submit(repo);
        expect(result, isA<LibraryFormApplySucceeded>());
        expect(repo.calls, <String>['createImageSetLocal', 'updateSettings']);
        expect(repo.lastScanOnStartup, isTrue);
        expect(repo.lastScanInterval, ScanInterval.daily);
        expect(repo.lastGroups, isEmpty);
      },
    );

    test('local root change calls updateLocalRoot', () async {
      final LocalLibrary original = _lib(
        kind: 'local',
        catalogKind: 'comic',
        root: r'D:\comics',
        name: 'Alpha',
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.fromLibrary(
        original,
      ).copyWith(rootPath: r'D:\comics2').submit(repo, original: original);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect((result as LibraryFormApplySucceeded).rootChanged, isTrue);
      expect(repo.calls, <String>['updateLocalRoot']);
      expect(repo.lastRoot, r'D:\comics2');
    });

    test('remote password empty does not pass password override', () async {
      final LocalLibrary original = _lib(
        kind: 'remote',
        catalogKind: 'comic',
        root: 'https://a.example/dav',
        name: 'Nas',
        username: 'u',
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      await LibraryForm.fromLibrary(original)
          .copyWith(rootPath: 'https://b.example/dav')
          .submit(repo, original: original);
      expect(repo.calls, contains('updateRemote'));
      expect(repo.lastPassword, isNull);
    });
  });
}

extension on LibraryForm {
  Future<LibraryFormApplyResult> submit(
    LibraryRepository repository, {
    LocalLibrary? original,
  }) =>
      SubmitLibraryFormUseCase(repository, _Events())(this, original: original);
}

class _Events implements DomainEventPublisher {
  final events = <DomainEvent>[];
  @override
  void publish(DomainEvent event) => events.add(event);
}
