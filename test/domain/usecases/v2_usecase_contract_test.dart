import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/series_repo.dart';
import 'package:hentai_library/domain/usecases/assign_library_comic_to_series_usecase.dart';
import 'package:hentai_library/domain/usecases/update_library_comic_meta_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockLibraryComicRepository extends Mock implements ComicRepository {}

class MockLibrarySeriesRepository extends Mock implements SeriesRepository {}

void main() {
  group('v2 usecase contracts', () {
    test(
      'UpdateLibraryComicMetaUseCase delegates to repo.updateUserMeta',
      () async {
        final repo = MockLibraryComicRepository();
        when(
          () => repo.updateUserMeta(
            any(),
            title: any(named: 'title'),
            authors: any(named: 'authors'),
            contentRating: any(named: 'contentRating'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async {});

        final usecase = UpdateLibraryComicMetaUseCase(repo);
        await usecase(
          'c1',
          title: 'T',
          authors: ['A'],
          contentRating: ContentRating.safe,
          tags: [Tag(name: 'tag1')],
        );

        verify(
          () => repo.updateUserMeta(
            'c1',
            title: 'T',
            authors: ['A'],
            contentRating: ContentRating.safe,
            tags: [Tag(name: 'tag1')],
          ),
        ).called(1);
      },
    );

    test(
      'AssignLibraryComicToSeriesUseCase delegates to repo.assignComicExclusive',
      () async {
        final repo = MockLibrarySeriesRepository();
        when(
          () => repo.assignComicExclusive(
            comicId: any(named: 'comicId'),
            targetSeriesId: any(named: 'targetSeriesId'),
            order: any(named: 'order'),
          ),
        ).thenAnswer((_) async {});

        final usecase = AssignLibraryComicToSeriesUseCase(repo);
        await usecase(comicId: 'c1', targetSeriesId: 's1', order: 10);

        verify(
          () => repo.assignComicExclusive(
            comicId: 'c1',
            targetSeriesId: 's1',
            order: 10,
          ),
        ).called(1);
      },
    );
  });
}
