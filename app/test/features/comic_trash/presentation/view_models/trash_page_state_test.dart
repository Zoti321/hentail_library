import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/comic_trash/comic_purge_policy.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_state.dart';

TrashedComic _trashed(String id, {bool remote = false}) {
  final DateTime t = DateTime.utc(2026, 10, 2);
  return (
    comic: Comic(
      comicId: id,
      path: '/lib/$id.cbz',
      resourceType: ResourceType.cbz,
      resourceSize: 1,
      createdAt: t,
      lastUpdatedAt: t,
      title: id,
      pageCount: 1,
    ),
    deletedAt: t,
    libraryName: remote ? 'Remote' : 'Local',
    isRemote: remote,
  );
}

TrashPageState _stateWith(List<TrashedComic> items) {
  return const TrashPageState().withItems(
    items: items,
    totalCount: items.length,
    counts: (total: items.length, local: 0, remote: 0),
    loadedPage: 1,
    hasReachedEnd: true,
  );
}

void main() {
  group('multi-select', () {
    test('toggleSelected enters selection mode and toggles membership', () {
      final TrashPageState state = _stateWith(<TrashedComic>[
        _trashed('a'),
        _trashed('b'),
      ]);

      final TrashPageState selected = state.toggleSelected('a');
      expect(selected.selectionMode, isTrue);
      expect(selected.selectedIds, <String>{'a'});

      expect(selected.toggleSelected('a').selectedIds, isEmpty);
    });

    test('toggleSelectAllLoaded selects all then clears', () {
      final TrashPageState state = _stateWith(<TrashedComic>[
        _trashed('a'),
        _trashed('b'),
      ]).enterSelection();

      final TrashPageState all = state.toggleSelectAllLoaded();
      expect(all.selectedIds, <String>{'a', 'b'});
      expect(all.allLoadedSelected, isTrue);

      expect(all.toggleSelectAllLoaded().selectedIds, isEmpty);
    });

    test('exitSelection clears selection', () {
      final TrashPageState state = _stateWith(<TrashedComic>[_trashed('a')])
          .toggleSelected('a');

      final TrashPageState exited = state.exitSelection();
      expect(exited.selectionMode, isFalse);
      expect(exited.selectedIds, isEmpty);
    });

    test('withItems drops selection for comics no longer listed', () {
      final TrashPageState state = _stateWith(<TrashedComic>[
        _trashed('a'),
        _trashed('b'),
      ]).toggleSelectAllLoaded();

      final TrashPageState refreshed = state.withItems(
        items: <TrashedComic>[_trashed('b')],
        totalCount: 1,
        counts: (total: 1, local: 1, remote: 0),
        loadedPage: 1,
        hasReachedEnd: true,
      );
      expect(refreshed.selectedIds, <String>{'b'});
      expect(refreshed.selectionMode, isTrue);
    });
  });

  group('Local / Remote counts', () {
    test('selectedPurgeCounts splits selected items by kind', () {
      final TrashPageState state = _stateWith(<TrashedComic>[
        _trashed('l1'),
        _trashed('l2'),
        _trashed('r1', remote: true),
      ]).toggleSelected('l1').toggleSelected('r1');

      expect(state.selectedPurgeCounts, (local: 1, remote: 1));
    });

    test('allPurgeCounts uses whole-trash counts', () {
      final TrashPageState state = const TrashPageState().copyWith(
        counts: (total: 7, local: 4, remote: 3),
      );

      expect(state.allPurgeCounts, (local: 4, remote: 3));
    });
  });

  group('purge confirm copy', () {
    test('branches by total and kind mix', () {
      expect(
        purgeConfirmCopyFor((local: 1, remote: 0)),
        PurgeConfirmCopy.singleLocal,
      );
      expect(
        purgeConfirmCopyFor((local: 0, remote: 1)),
        PurgeConfirmCopy.singleRemote,
      );
      expect(
        purgeConfirmCopyFor((local: 3, remote: 0)),
        PurgeConfirmCopy.batchLocal,
      );
      expect(
        purgeConfirmCopyFor((local: 0, remote: 2)),
        PurgeConfirmCopy.batchRemote,
      );
      expect(
        purgeConfirmCopyFor((local: 1, remote: 1)),
        PurgeConfirmCopy.mixed,
      );
    });

    test('acknowledgement gate required for Local and Remote targets', () {
      expect(purgeRequiresAcknowledgement((local: 1, remote: 5)), isTrue);
      expect(purgeRequiresAcknowledgement((local: 0, remote: 5)), isTrue);
      expect(purgeRequiresAcknowledgement((local: 2, remote: 0)), isTrue);
      expect(purgeRequiresAcknowledgement((local: 0, remote: 0)), isFalse);
    });
  });

  group('purge result summary', () {
    ComicPurgeResult result(int succeeded, int failed) =>
        (succeeded: succeeded, failed: failed, errorSamples: const <String>[]);

    test('maps success / partial / failure / nothing', () {
      expect(purgeSummaryKindFor(result(0, 0)), PurgeSummaryKind.nothing);
      expect(purgeSummaryKindFor(result(3, 0)), PurgeSummaryKind.allSucceeded);
      expect(purgeSummaryKindFor(result(2, 1)), PurgeSummaryKind.partial);
      expect(purgeSummaryKindFor(result(0, 2)), PurgeSummaryKind.allFailed);
    });
  });
}
