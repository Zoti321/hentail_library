import 'dart:async';

import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_metadata_use_case_providers.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_repository_providers.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_edit_session_notifier.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_edit_ui_state.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_membership_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_sort_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _LockRepository implements ComicUserMetadataRepository {
  final completion = Completer<void>();
  final calls = <({String comicId, bool? title})>[];

  @override
  Future<void> setMetaLocks(
    String comicId, {
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  }) {
    calls.add((comicId: comicId, title: title));
    return completion.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic() => Comic.restore(
  comicId: 'comic-1',
  path: '/library/series/book.cbz',
  resourceType: ResourceType.cbz,
  resourceSize: 0,
  createdAt: DateTime.utc(2026),
  lastUpdatedAt: DateTime.utc(2026),
  title: 'Original title',
  pageCount: 1,
);

void main() {
  test(
    'late membership retains the current draft title in its Smart facet scope',
    () async {
      final membership = Completer<SeriesItemMembership?>();
      final requested = Completer<void>();
      final comic = _comic();
      final container = ProviderContainer(
        overrides: [
          findSeriesItemMembershipQueryProvider.overrideWithValue((id) {
            expect(id, comic.comicId);
            requested.complete();
            return membership.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      final provider = comicMetadataEditSessionProvider(comic);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final session = container.read(provider.notifier);
      await requested.future;
      session.updateDraft(
        container.read(provider).draft.copyWith(title: 'Edited while waiting'),
      );
      membership.complete((
        seriesId: 'series-1',
        sortOrder: 2.5,
        sortOrderLocked: true,
      ));
      await container.pump();
      final state = container.read(provider);
      expect(state.draft.title, 'Edited while waiting');
      expect(state.smartFacetScope, (
        comicId: comic.comicId,
        title: 'Edited while waiting',
        resourcePath: comic.path,
        seriesId: 'series-1',
      ));
      expect(state.seed, (
        seriesId: 'series-1',
        sortOrder: 2.5,
        sortOrderLocked: true,
      ));
      expect(state.draft.seriesSortOrderText, '2.5');
      session.updateDraft(
        state.draft.copyWith(title: 'Edited after membership'),
      );
      expect(
        container.read(provider).smartFacetScope.title,
        'Edited after membership',
      );
      expect(container.read(provider).smartFacetScope.seriesId, 'series-1');
    },
  );

  test(
    'mounted session updates locks and clears saving after a successful commit',
    () async {
      final repository = _LockRepository();
      final committed = Completer<ComicMetadataApplyResult>();
      var applyCalls = 0;
      final comic = _comic();
      final container = ProviderContainer(
        overrides: [
          findSeriesItemMembershipQueryProvider.overrideWithValue(
            (_) async => null,
          ),
          comicUserMetadataRepositoryProvider.overrideWithValue(repository),
          comicMetadataApplyCommandProvider.overrideWithValue((_, _) {
            applyCalls++;
            return committed.future;
          }),
          persistSeriesItemSortCommandProvider.overrideWithValue(
            ({
              required comicId,
              required seed,
              required sortOrder,
              required draftLocked,
            }) async => false,
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = comicMetadataEditSessionProvider(comic);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final session = container.read(provider.notifier);
      await container.pump();
      final locking = session.setLock(title: true);
      expect(container.read(provider).locks.title, isFalse);
      repository.completion.complete();
      await locking;
      expect(container.read(provider).locks.title, isTrue);
      session.updateDraft(
        container.read(provider).draft.copyWith(title: 'Saved title'),
      );
      final saving = session.save();
      expect(container.read(provider).saving, isTrue);
      committed.complete(const ComicMetadataApplySucceeded());
      expect(await saving, ComicMetadataEditSaveResult.succeeded);
      expect(container.read(provider).saving, isFalse);
      expect(applyCalls, 1);
      expect(repository.calls, [(comicId: comic.comicId, title: true)]);
    },
  );

  for (final disposal in ['container', 'listener']) {
    for (final fails in [false, true]) {
      test(
        'pending save ${fails ? 'failure' : 'success'} survives $disposal disposal',
        () async {
          final committed = Completer<ComicMetadataApplyResult>();
          final failure = StateError('original write failure');
          var applyCalls = 0;
          var sortCalls = 0;
          final comic = _comic();
          final container = ProviderContainer(
            overrides: [
              findSeriesItemMembershipQueryProvider.overrideWithValue(
                (_) async => null,
              ),
              comicMetadataApplyCommandProvider.overrideWithValue((
                form,
                original,
              ) {
                applyCalls++;
                expect(form.title, 'Saved title');
                expect(original, same(comic));
                return committed.future;
              }),
              persistSeriesItemSortCommandProvider.overrideWithValue(({
                required comicId,
                required seed,
                required sortOrder,
                required draftLocked,
              }) async {
                sortCalls++;
                return true;
              }),
            ],
          );
          var disposed = false;
          addTearDown(() {
            if (!disposed) container.dispose();
          });
          final provider = comicMetadataEditSessionProvider(comic);
          final subscription = container.listen(provider, (_, _) {});
          final session = container.read(provider.notifier);
          await container.pump();
          session.updateDraft(
            container.read(provider).draft.copyWith(title: 'Saved title'),
          );
          final saving = session.save();
          expect(container.read(provider).saving, isTrue);
          expect(await session.save(), ComicMetadataEditSaveResult.busy);
          final observed = expectLater(
            saving,
            fails
                ? throwsA(same(failure))
                : completion(ComicMetadataEditSaveResult.succeeded),
          );
          if (disposal == 'container') {
            container.dispose();
            disposed = true;
          } else {
            subscription.close();
            await container.pump();
          }
          if (fails) {
            committed.completeError(failure);
          } else {
            committed.complete(const ComicMetadataApplySucceeded());
          }
          await observed;
          expect(applyCalls, 1);
          expect(sortCalls, 0);
        },
      );

      test(
        'pending lock ${fails ? 'failure' : 'success'} survives $disposal disposal',
        () async {
          final repository = _LockRepository();
          final failure = StateError('original lock failure');
          final comic = _comic();
          final container = ProviderContainer(
            overrides: [
              findSeriesItemMembershipQueryProvider.overrideWithValue(
                (_) async => null,
              ),
              comicUserMetadataRepositoryProvider.overrideWithValue(repository),
            ],
          );
          var disposed = false;
          addTearDown(() {
            if (!disposed) container.dispose();
          });
          final provider = comicMetadataEditSessionProvider(comic);
          final subscription = container.listen(provider, (_, _) {});
          final session = container.read(provider.notifier);
          await container.pump();
          final locking = session.setLock(title: true);
          final observed = expectLater(
            locking,
            fails ? throwsA(same(failure)) : completes,
          );
          if (disposal == 'container') {
            container.dispose();
            disposed = true;
          } else {
            subscription.close();
            await container.pump();
          }
          if (fails) {
            repository.completion.completeError(failure);
          } else {
            repository.completion.complete();
          }
          await observed;
          expect(repository.calls, [(comicId: comic.comicId, title: true)]);
        },
      );
    }
  }
}
