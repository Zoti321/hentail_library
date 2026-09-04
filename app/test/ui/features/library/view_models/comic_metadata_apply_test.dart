import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/ui/core/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_apply.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
import 'package:riverpod/misc.dart' show ProviderOrFamily;
import 'package:test/test.dart';

class _RecordingComicRepository implements ComicRepository {
  int callCount = 0;

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
    callCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic({List<Tag> tags = const <Tag>[]}) {
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
    tags: tags,
    languages: const [],
    parodies: const [],
    characters: const [],
    pageCount: 1,
  );
}

void main() {
  group('refreshComicMetadataDictionaries', () {
    test('invalidates only providers for written dictionaries', () {
      final List<ProviderOrFamily> invalidated = <ProviderOrFamily>[];

      refreshComicMetadataDictionaries(
        invalidated.add,
        const ComicMetadataApplySucceeded(
          tagsWritten: true,
          charactersWritten: true,
        ),
      );

      expect(invalidated, <ProviderOrFamily>[
        allTagsProvider,
        tagsForComicMetadataFormProvider,
        allCharactersProvider,
        charactersForComicMetadataFormProvider,
        libraryDistinctCharactersProvider,
      ]);
      expect(invalidated.contains(allParodiesProvider), isFalse);
    });

    test('no-ops when no dictionary fields were written', () {
      final List<ProviderOrFamily> invalidated = <ProviderOrFamily>[];

      refreshComicMetadataDictionaries(
        invalidated.add,
        const ComicMetadataApplySucceeded(),
      );

      expect(invalidated, isEmpty);
    });
  });

  group('applyComicMetadataForm', () {
    test('applies form and invalidates tag list when tags change', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<ProviderOrFamily> invalidated = <ProviderOrFamily>[];

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original).addTag('new-tag'),
        original,
        invalidate: invalidated.add,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(invalidated, <ProviderOrFamily>[
        allTagsProvider,
        tagsForComicMetadataFormProvider,
      ]);
    });

    test('invalidates parody and character lists when those fields change',
        () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<ProviderOrFamily> invalidated = <ProviderOrFamily>[];

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original)
            .addParody('Fate')
            .addCharacter('Saber'),
        original,
        invalidate: invalidated.add,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(invalidated, <ProviderOrFamily>[
        allParodiesProvider,
        parodiesForComicMetadataFormProvider,
        libraryDistinctParodiesProvider,
        allCharactersProvider,
        charactersForComicMetadataFormProvider,
        libraryDistinctCharactersProvider,
      ]);
    });

    test('does not invalidate when only title changes', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<ProviderOrFamily> invalidated = <ProviderOrFamily>[];

      await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original).copyWith(title: '新标题'),
        original,
        invalidate: invalidated.add,
      );

      expect(repo.callCount, 1);
      expect(invalidated, isEmpty);
    });
  });
}
