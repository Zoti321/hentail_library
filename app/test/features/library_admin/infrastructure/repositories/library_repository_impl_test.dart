import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/remote_library_credential_store.dart';
import 'package:hentai_library/features/library_admin/infrastructure/repositories/library_repository_impl.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/library.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:test/test.dart';

class _LibraryApi implements RustLibApi {
  _LibraryApi(this.calls);

  final List<String> calls;
  final libraries = <String>{'remote'};
  final comicIds = <String, List<String>>{
    'remote': ['kept-comic'],
  };
  LibraryDto? registration;
  Object? failure;
  final origin = StackTrace.fromString('core-delete-origin');

  @override
  void crateApiLibraryDeleteLibraryFrb({required String libraryId}) {
    calls.add('core:$libraryId');
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, origin);
    libraries.remove(libraryId);
    comicIds.remove(libraryId);
  }

  @override
  LibraryDto crateApiLibraryCreateRemoteLibraryFrb({
    required String rootUrl,
    required String username,
    required bool allowHttp,
    String? name,
  }) {
    calls.add('register:$rootUrl');
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, origin);
    final existing = libraries.contains('remote');
    libraries.add('remote');
    return registration = LibraryDto(
      libraryId: 'remote',
      kind: 'remote',
      catalogKind: 'comic',
      rootPath: rootUrl,
      name: existing ? 'Existing Library' : name ?? 'Remote',
      enabledResourceFormatCategories: const [],
      createdAt: PlatformInt64Util.from(123),
      username: username,
      allowHttp: allowHttp,
      scanOnStartup: false,
      scanInterval: ScanIntervalDto.disabled,
      pinned: true,
      sidebarOrder: 0,
    );
  }

  @override
  LibraryDto crateApiLibraryCreateImageSetLocalLibraryFrb({
    required String rootPath,
    String? name,
  }) {
    calls.add('image-set:$rootPath');
    return LibraryDto(
      libraryId: 'image-set',
      kind: 'local',
      catalogKind: 'image_set',
      rootPath: rootPath,
      name: name ?? 'Gallery',
      enabledResourceFormatCategories: const [],
      createdAt: PlatformInt64Util.from(456),
      username: '',
      allowHttp: false,
      scanOnStartup: false,
      scanInterval: ScanIntervalDto.disabled,
      pinned: false,
      sidebarOrder: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credentials implements RemoteLibraryCredentialStore {
  _Credentials(this.calls);

  final List<String> calls;
  final passwords = <String, String>{'remote': 'saved-password'};
  Future<void>? pending;
  Object? failure;
  final origin = StackTrace.fromString('secure-store-origin');

  @override
  Future<String?> readPassword(String libraryId) async => passwords[libraryId];

  @override
  Future<void> savePassword({
    required String libraryId,
    required String password,
  }) async {
    calls.add('save:$libraryId');
    await pending;
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, origin);
    passwords[libraryId] = password;
  }

  @override
  Future<void> deletePassword(String libraryId) async {
    calls.add('credentials:$libraryId');
    await pending;
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, origin);
    passwords.remove(libraryId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late List<String> calls;
  late _LibraryApi api;
  late _Credentials credentials;
  late LibraryRepositoryImpl repository;

  setUp(() {
    calls = [];
    api = _LibraryApi(calls);
    credentials = _Credentials(calls);
    RustLib.initMock(api: api);
    addTearDown(RustLib.dispose);
    repository = LibraryRepositoryImpl(credentials: credentials);
  });

  test('image set create maps catalogKind from core projection', () async {
    final LocalLibrary library = await repository.createImageSetLocal(
      '/images',
      name: 'Gallery',
    );
    expect(library.catalogKind, 'image_set');
    expect(library.kind, 'local');
    expect(library.rootPath, '/images');
    expect(calls, ['image-set:/images']);
  });

  for (final existing in [false, true]) {
    test(
      'failed credential save preserves committed registration, existing: $existing',
      () async {
        if (!existing) {
          api.libraries.clear();
          api.comicIds.clear();
          credentials.passwords.clear();
        }
        final secureError = StateError('credential save failed');
        credentials.failure = secureError;
        try {
          await repository.createRemote(
            rootUrl: 'https://example.test/dav',
            username: 'new-user',
            password: 'new-password',
            allowHttp: false,
          );
          fail('credential save must fail');
        } catch (error, stack) {
          expect(error, same(secureError));
          expect(stack.toString(), credentials.origin.toString());
        }
        expect(api.libraries, contains('remote'));
        expect(api.registration?.username, 'new-user');
        expect(api.comicIds['remote'], existing ? ['kept-comic'] : isNull);
        expect(
          credentials.passwords['remote'],
          existing ? 'saved-password' : isNull,
        );
        expect(calls, ['register:https://example.test/dav', 'save:remote']);
      },
    );
  }

  test('core registration rejection does not save credentials', () async {
    final coreError = HentaiErrorDto(
      code: 'Validation',
      message: 'registration rejected',
    );
    api.failure = coreError;
    try {
      await repository.createRemote(
        rootUrl: 'https://example.test/dav',
        username: 'new-user',
        password: 'new-password',
        allowHttp: false,
      );
      fail('registration must fail');
    } on AppException catch (error, stack) {
      expect(error.cause, same(coreError));
      expect(stack.toString(), api.origin.toString());
    }
    expect(credentials.passwords['remote'], 'saved-password');
    expect(api.comicIds['remote'], ['kept-comic']);
    expect(calls, ['register:https://example.test/dav']);
  });

  test('successful registration waits for credential save and returns the core projection', () async {
    final pending = Completer<void>();
    credentials.pending = pending.future;
    var completed = false;
    Future<void> register() async {
      final library = await repository.createRemote(
        rootUrl: 'https://example.test/dav',
        username: 'new-user',
        password: 'new-password',
        allowHttp: false,
        name: 'Ignored duplicate name',
      );
      expect(library.libraryId, 'remote');
      expect(library.rootPath, api.registration?.rootPath);
      expect(library.username, 'new-user');
      expect(library.name, 'Existing Library');
      completed = true;
    }

    final result = register();
    expect(calls, ['register:https://example.test/dav', 'save:remote']);
    expect(completed, isFalse);
    expect(credentials.passwords['remote'], 'saved-password');
    pending.complete();
    await result;
    expect(completed, isTrue);
    expect(credentials.passwords['remote'], 'new-password');
    expect(api.comicIds['remote'], ['kept-comic']);
    expect(calls, ['register:https://example.test/dav', 'save:remote']);
  });

  for (final code in ['Validation', 'DbQueryFailed']) {
    for (final cleanupFails in [false, true]) {
      test(
        'core rejection preserves credentials and its mapped error: $code, cleanup fails: $cleanupFails',
        () async {
          final coreError = HentaiErrorDto(
            code: code,
            message: 'library deletion rejected',
          );
          api.failure = coreError;
          if (cleanupFails) {
            credentials.failure = StateError('credential storage unavailable');
          }

          try {
            await repository.delete('remote');
            fail('delete must fail');
          } on AppException catch (error, stack) {
            expect(error.cause, same(coreError));
            expect(error.message, 'library deletion rejected');
            expect(error.stackTrace.toString(), api.origin.toString());
            expect(stack.toString(), api.origin.toString());
          }

          expect(api.libraries, contains('remote'));
          expect(
            await repository.readRemotePassword('remote'),
            'saved-password',
          );
          expect(calls, ['core:remote']);
        },
      );
    }
  }

  test(
    'successful core deletion waits for credential cleanup exactly once',
    () async {
      final pending = Completer<void>();
      credentials.pending = pending.future;
      var completed = false;
      Future<void> delete() async {
        await repository.delete('remote');
        completed = true;
      }

      final result = delete();
      expect(api.libraries, isEmpty);
      expect(calls, ['core:remote', 'credentials:remote']);
      expect(completed, isFalse);
      expect(credentials.passwords, contains('remote'));
      pending.complete();
      await result;

      expect(completed, isTrue);
      expect(credentials.passwords, isEmpty);
      expect(calls, ['core:remote', 'credentials:remote']);
    },
  );

  test(
    'credential failure propagates after committed deletion without retry',
    () async {
      final secureError = StateError('credential cleanup failed');
      credentials.failure = secureError;

      try {
        await repository.delete('remote');
        fail('credential cleanup must fail');
      } catch (error, stack) {
        expect(error, same(secureError));
        expect(stack.toString(), credentials.origin.toString());
      }

      expect(api.libraries, isEmpty);
      expect(credentials.passwords, contains('remote'));
      expect(calls, ['core:remote', 'credentials:remote']);
    },
  );
}
