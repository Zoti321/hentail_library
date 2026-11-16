import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/author_repository_impl.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:test/test.dart';

class _AuthorApi implements RustLibApi {
  _AuthorApi(this.rename);

  final Future<void> Function() rename;
  final List<(String, String)> renames = [];

  @override
  Future<void> crateApiAuthorRenameAuthorByIdFrb({
    required PlatformInt64 authorId,
    required String newName,
  }) {
    renames.add((authorId.toString(), newName));
    return rename();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NamedFacets implements NamedFacetManagementRepository {
  final List<(ManagedNamedFacetKind, String, String)> renames = [];

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    renames.add((kind, oldName, newName));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'repository uses the identity RPC and waits for its completion',
    () async {
      final completion = Completer<void>();
      final api = _AuthorApi(() => completion.future);
      RustLib.initMock(api: api);
      addTearDown(RustLib.dispose);
      final names = _NamedFacets();
      final repo = AuthorRepositoryImpl(namedFacets: names);
      var completed = false;

      final pending = repo.renameById(9007199254740993, ' Bob ').then((_) {
        completed = true;
      });
      await Future<void>.value();
      expect(api.renames, [('9007199254740993', ' Bob ')]);
      expect(names.renames, isEmpty);
      expect(completed, isFalse);

      completion.complete();
      await pending;
      expect(completed, isTrue);
      expect(api.renames, hasLength(1));
    },
  );

  test('identity RPC maps structured errors with the original cause', () async {
    const failure = HentaiErrorDto(
      code: 'Validation',
      message: 'author name already exists',
    );
    final api = _AuthorApi(() async => throw failure);
    RustLib.initMock(api: api);
    addTearDown(RustLib.dispose);
    final names = _NamedFacets();
    final repo = AuthorRepositoryImpl(namedFacets: names);

    await expectLater(
      repo.renameById(42, 'Bob'),
      throwsA(
        isA<AppException>()
            .having((error) => error.cause, 'cause', same(failure))
            .having((error) => error.message, 'message', failure.message),
      ),
    );

    expect(api.renames, [('42', 'Bob')]);
    expect(names.renames, isEmpty);
  });

  test('identity RPC preserves non-FRB errors without retry', () async {
    final failure = StateError('native call unavailable');
    final api = _AuthorApi(() async => throw failure);
    RustLib.initMock(api: api);
    addTearDown(RustLib.dispose);
    final names = _NamedFacets();
    final repo = AuthorRepositoryImpl(namedFacets: names);

    await expectLater(repo.renameById(42, 'Bob'), throwsA(same(failure)));

    expect(api.renames, [('42', 'Bob')]);
    expect(names.renames, isEmpty);
  });

  test('name-based management keeps its existing owner path', () async {
    final names = _NamedFacets();
    final repo = AuthorRepositoryImpl(namedFacets: names);

    await repo.rename('Alice', 'Alicia');

    expect(names.renames, [(ManagedNamedFacetKind.author, 'Alice', 'Alicia')]);
  });
}
