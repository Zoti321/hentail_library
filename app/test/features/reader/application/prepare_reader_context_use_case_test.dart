import 'package:test/test.dart';
import 'package:hentai_library/features/reader/application/prepare_reader_context_use_case.dart';
import 'package:hentai_library/shared/domain/contracts/comic_read_query.dart';

class _Comics implements ComicReadQuery {
  final calls = <List<String>>[];
  @override
  Future<String> displayTitleById(String id) async => 'fallback:$id';
  @override
  Future<Map<String, String>> displayTitlesByIds(List<String> ids) async {
    calls.add(ids);
    return {for (final id in ids) id: 'title:$id'};
  }

  @override
  Future<ComicReadSnapshot?> findById(String id) async => null;
}

void main() {
  for (final series in [false, true]) {
    for (final mode in ['normal', 'incognito', 'first']) {
      test('context series=$series mode=$mode', () async {
        final comics = _Comics();
        var resumeCalls = 0;
        final useCase = PrepareReaderContextUseCase(
          comics: comics,
          seriesContext: (id) async => series
              ? (
                  seriesId: 's',
                  seriesName: 'S',
                  orderedComicIds: ['b', 'a'],
                  currentIndex: 1,
                )
              : null,
          resumePage: (id) async {
            resumeCalls++;
            expect(id, 'a');
            return 7;
          },
        );
        final context = await useCase(
          comicId: ' a ',
          incognito: mode == 'incognito',
          startFromFirstPage: mode == 'first',
        );
        expect(context.preferredPageIndex, mode == 'normal' ? 7 : null);
        expect(resumeCalls, mode == 'normal' ? 1 : 0);
        expect(
          context.items.map((e) => e.comicId),
          series ? ['b', 'a'] : ['a'],
        );
        expect(context.items.last.title, series ? 'title:a' : 'fallback:a');
        expect(
          comics.calls,
          series
              ? [
                  ['b', 'a'],
                ]
              : isEmpty,
        );
      });
    }
  }
}
