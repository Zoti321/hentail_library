import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_editor_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _RecordingComicRepository implements ComicRepository {
  final List<String> updatedTitles = <String>[];
  final List<({String comicId, bool? title})> lockCalls =
      <({String comicId, bool? title})>[];

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    List? authors,
    ContentRating? contentRating,
    List? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
  }) async {
    updatedTitles.add(title ?? '');
  }

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
  }) async {
    lockCalls.add((comicId: comicId, title: title));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingSeriesRepository implements SeriesRepository {
  SeriesItemMembership? membership;
  final List<double> writtenSortOrders = <double>[];

  @override
  Future<SeriesItemMembership?> findMembershipByComicId(String comicId) async =>
      membership;

  @override
  Future<void> updateSeriesItemSortOrder({
    required String seriesId,
    required String comicId,
    required double sortOrder,
  }) async {
    writtenSortOrders.add(sortOrder);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentRevisionPort implements LibraryRevisionPort {
  @override
  Stream<void> watchRevision() => const Stream<void>.empty();
}

Comic _comic() {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic(
    comicId: 'comic-1',
    path: '/library/comic-1',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: now,
    lastUpdatedAt: now,
    title: '原标题',
    contentRating: ContentRating.safe,
    authors: const [],
    tags: const [],
    languages: const [],
    parodies: const [],
    characters: const [],
    pageCount: 1,
  );
}

const SeriesItemMembership _membership = (
  seriesId: 'series-1',
  sortOrder: 1,
  sortOrderLocked: false,
);

void main() {
  late _RecordingComicRepository comicRepo;
  late _RecordingSeriesRepository seriesRepo;
  late ProviderContainer container;

  setUp(() {
    comicRepo = _RecordingComicRepository();
    seriesRepo = _RecordingSeriesRepository();
    container = ProviderContainer(
      overrides: <Override>[
        comicRepoProvider.overrideWithValue(comicRepo),
        seriesRepoProvider.overrideWithValue(seriesRepo),
        libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
      ],
    );
  });

  tearDown(() => container.dispose());

  ComicMetadataEditorNotifier editor() =>
      container.read(comicMetadataEditorProvider.notifier);

  int revision() => container.read(libraryRevisionProvider).revision;

  test('apply persists the form and bumps library revision', () async {
    final Comic original = _comic();
    final int before = revision();

    final ComicMetadataApplyResult result = await editor().apply(
      ComicMetadataForm.fromComic(original).copyWith(title: '新标题'),
      original,
    );

    expect(result, isA<ComicMetadataApplySucceeded>());
    expect(comicRepo.updatedTitles, <String>['新标题']);
    expect(revision(), greaterThan(before));
  });

  test('setLocks forwards the lock patch to the repository', () async {
    await editor().setLocks('comic-1', title: true);

    expect(comicRepo.lockCalls, <({String comicId, bool? title})>[
      (comicId: 'comic-1', title: true),
    ]);
  });

  test(
    'findSeriesMembership reads membership from series repository',
    () async {
      seriesRepo.membership = _membership;

      expect(await editor().findSeriesMembership('comic-1'), _membership);
    },
  );

  test('persistSeriesSort writes a changed order and bumps revision', () async {
    final int before = revision();

    await editor().persistSeriesSort(
      comicId: 'comic-1',
      seed: _membership,
      sortOrder: 2,
      draftLocked: false,
    );

    expect(seriesRepo.writtenSortOrders, <double>[2]);
    expect(revision(), greaterThan(before));
  });

  test('persistSeriesSort leaves revision untouched when unchanged', () async {
    final int before = revision();

    await editor().persistSeriesSort(
      comicId: 'comic-1',
      seed: _membership,
      sortOrder: 1,
      draftLocked: false,
    );

    expect(seriesRepo.writtenSortOrders, isEmpty);
    expect(revision(), before);
  });
}
