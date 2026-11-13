import 'dart:async';

import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import '../../../../../support/fakes/author_repository_test_fakes.dart';

class _PendingAuthorRepository extends EmptyAuthorRepository {
  final Completer<void> completion = Completer<void>();
  final List<(int, String)> renames = [];

  @override
  Future<void> renameById(int authorId, String newName) {
    renames.add((authorId, newName));
    return completion.future;
  }

  @override
  Future<void> rename(String oldName, String newName) =>
      throw StateError('Name-based rename is not an identity command');
}

void main() {
  test(
    'rename passes identity and refreshes only its detail after success',
    () async {
      final repo = _PendingAuthorRepository();
      var detailReads = 0;
      var otherReads = 0;
      final detail = authorDetailProvider(42);
      final other = authorDetailProvider(7);
      final container = ProviderContainer(
        overrides: [
          authorRepoProvider.overrideWithValue(repo),
          detail.overrideWith((_) async {
            detailReads++;
            return null;
          }),
          other.overrideWith((_) async {
            otherReads++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(detail, (_, _) {});
      container.listen(other, (_, _) {});
      await container.read(detail.future);
      await container.read(other.future);

      final pending = container
          .read(authorDetailCommandsProvider)
          .rename(authorId: 42, newName: 'Bob');
      await container.pump();
      expect(repo.renames, [(42, 'Bob')]);
      expect(detailReads, 1);
      expect(otherReads, 1);

      repo.completion.complete();
      await pending;
      await container.pump();
      await container.read(detail.future);
      expect(detailReads, 2);
      expect(otherReads, 1);
    },
  );

  test(
    'rename failure propagates unchanged without invalidating detail',
    () async {
      final repo = _PendingAuthorRepository();
      var detailReads = 0;
      final detail = authorDetailProvider(42);
      final container = ProviderContainer(
        overrides: [
          authorRepoProvider.overrideWithValue(repo),
          detail.overrideWith((_) async {
            detailReads++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(detail, (_, _) {});
      await container.read(detail.future);
      final failure = StateError('name already exists');

      final pending = container
          .read(authorDetailCommandsProvider)
          .rename(authorId: 42, newName: 'Bob');
      final expectation = expectLater(pending, throwsA(same(failure)));
      repo.completion.completeError(failure);
      await expectation;
      await container.pump();

      expect(repo.renames, [(42, 'Bob')]);
      expect(detailReads, 1);
    },
  );

  test(
    'disposing during rename does not turn a committed write into failure',
    () async {
      final repo = _PendingAuthorRepository();
      final container = ProviderContainer(
        overrides: [authorRepoProvider.overrideWithValue(repo)],
      );
      final pending = container
          .read(authorDetailCommandsProvider)
          .rename(authorId: 42, newName: 'Bob');
      container.dispose();

      repo.completion.complete();
      await pending;

      expect(repo.renames, [(42, 'Bob')]);
    },
  );
}
