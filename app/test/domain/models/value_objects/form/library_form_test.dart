import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/value_objects/form/library_form.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:test/test.dart';

class _RecordingLibraryRepository implements LibraryRepository {
  final List<String> calls = <String>[];
  String? lastName;
  String? lastRoot;
  String? lastPassword;
  List<FormatGroup>? lastGroups;
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
    required List<FormatGroup> groups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) async {
    calls.add('updateSettings');
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
  required String root,
  required String name,
  String username = '',
  bool allowHttp = false,
  List<FormatGroup>? groups,
  bool scanOnStartup = false,
  ScanInterval scanInterval = ScanInterval.disabled,
}) {
  return (
    libraryId: 'lib-1',
    kind: kind,
    rootPath: root,
    name: name,
    enabledFormatGroups: groups ??
        (kind == 'remote'
            ? <FormatGroup>[
                FormatGroup.pdf,
                FormatGroup.epub,
                FormatGroup.archive,
              ]
            : FormatGroup.all),
    username: username,
    allowHttp: allowHttp,
    scanOnStartup: scanOnStartup,
    scanInterval: scanInterval,
    pinned: true,
    sidebarOrder: 0,
  );
}

void main() {
  group('LibraryForm.validate', () {
    test('requires name and root', () {
      final LibraryFormValidation v = LibraryForm.createLocal().validate(
        isCreate: true,
      );
      expect(v.isValid, isFalse);
      expect(v.nameError, isNotNull);
      expect(v.rootError, isNotNull);
    });

    test('create remote requires password', () {
      final LibraryFormValidation v = LibraryForm.createRemote()
          .copyWith(name: 'R', rootPath: 'https://dav.example/c')
          .validate(isCreate: true);
      expect(v.passwordError, isNotNull);
    });

    test('edit remote allows empty password', () {
      final LibraryFormValidation v = LibraryForm.createRemote()
          .copyWith(name: 'R', rootPath: 'https://dav.example/c')
          .validate(isCreate: false);
      expect(v.isValid, isTrue);
    });
  });

  group('LibraryForm.create', () {
    test('local create then settings when scan differs', () async {
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.createLocal()
          .copyWith(
            name: 'Alpha',
            rootPath: r'D:\comics',
            scanOnStartup: true,
          )
          .create(repo);
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
          .create(repo);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect(repo.calls, <String>['createRemote']);
    });
  });

  group('LibraryForm.applyTo', () {
    test('no-op when unchanged', () async {
      final LocalLibrary original = _lib(
        kind: 'local',
        root: r'D:\comics',
        name: 'Alpha',
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.fromLibrary(
        original,
      ).applyTo(repo, original);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect(repo.calls, isEmpty);
    });

    test('local root change calls updateLocalRoot', () async {
      final LocalLibrary original = _lib(
        kind: 'local',
        root: r'D:\comics',
        name: 'Alpha',
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibraryFormApplyResult result = await LibraryForm.fromLibrary(
        original,
      ).copyWith(rootPath: r'D:\comics2').applyTo(repo, original);
      expect(result, isA<LibraryFormApplySucceeded>());
      expect(
        (result as LibraryFormApplySucceeded).rootChanged,
        isTrue,
      );
      expect(repo.calls, <String>['updateLocalRoot']);
      expect(repo.lastRoot, r'D:\comics2');
    });

    test('remote password empty does not pass password override', () async {
      final LocalLibrary original = _lib(
        kind: 'remote',
        root: 'https://a.example/dav',
        name: 'Nas',
        username: 'u',
      );
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      await LibraryForm.fromLibrary(original)
          .copyWith(rootPath: 'https://b.example/dav')
          .applyTo(repo, original);
      expect(repo.calls, contains('updateRemote'));
      expect(repo.lastPassword, isNull);
    });
  });
}
