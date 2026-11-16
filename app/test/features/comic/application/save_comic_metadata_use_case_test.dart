import 'package:test/test.dart';
import 'package:hentai_library/features/comic/application/save_comic_metadata_use_case.dart';
import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

void main() {
  final comic = Comic.restore(
    comicId: 'c',
    path: '/c',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: DateTime(2026),
    lastUpdatedAt: DateTime(2026),
    title: 'Title',
    pageCount: 2,
  );
  final form = ComicMetadataForm.fromComic(comic);
  const sort = (
    seed: (seriesId: 's', sortOrder: 1.0, sortOrderLocked: false),
    sortOrder: 2.0,
    draftLocked: false,
  );
  for (final failure in ['none', 'metadata', 'sort']) {
    test('save preserves order and partial commit: $failure', () async {
      final calls = <String>[];
      final useCase = SaveComicMetadataUseCase(
        apply: (form, original) async {
          calls.add('metadata');
          if (failure == 'metadata') throw StateError('metadata');
          return const ComicMetadataApplySucceeded(persisted: true);
        },
        persistSort:
            ({
              required comicId,
              required seed,
              required sortOrder,
              required draftLocked,
            }) async {
              calls.add('sort');
              if (failure == 'sort') throw StateError('sort');
              return true;
            },
      );
      if (failure == 'none') {
        await useCase(form, comic, sort: sort);
      } else {
        await expectLater(useCase(form, comic, sort: sort), throwsStateError);
      }
      expect(
        calls,
        failure == 'metadata' ? ['metadata'] : ['metadata', 'sort'],
      );
    });
  }
  test('unchanged metadata still permits optional sort; absent sort does not write it', () async {
    var sorts = 0;
    final useCase = SaveComicMetadataUseCase(
      apply: (f, c) async => const ComicMetadataApplySucceeded(),
      persistSort:
          ({
            required comicId,
            required seed,
            required sortOrder,
            required draftLocked,
          }) async {
            sorts++;
            return true;
          },
    );
    await useCase(form, comic);
    expect(sorts, 0);
    await useCase(form, comic, sort: sort);
    expect(sorts, 1);
  });
}
