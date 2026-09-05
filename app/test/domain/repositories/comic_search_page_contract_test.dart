import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:test/test.dart';

class _RecordingComicRepo implements ComicRepository {
  _RecordingComicRepo();

  final List<PageRequest> keywordPageRequests = <PageRequest>[];

  @override
  Future<PagedResult<Comic>> searchByKeywordPage({
    required String keyword,
    required PageRequest request,
  }) async {
    keywordPageRequests.add(request);
    final DateTime now = DateTime.utc(2026);
    final List<Comic> all = List<Comic>.generate(5, (int i) {
      return Comic(
        comicId: 'c$i',
        path: '/c$i',
        resourceType: ResourceType.zip,
        resourceSize: 1,
        createdAt: now,
        lastUpdatedAt: now,
        title: '$keyword-$i',
        pageCount: 1,
      );
    });
    final int start = request.offset.clamp(0, all.length);
    final int end = (start + request.pageSize).clamp(0, all.length);
    return PagedResult<Comic>(
      items: all.sublist(start, end),
      totalCount: all.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'searchByKeywordPage returns a page without requiring full vector',
    () async {
      final _RecordingComicRepo repo = _RecordingComicRepo();
      final PagedResult<Comic> page = await repo.searchByKeywordPage(
        keyword: 'foo',
        request: pageRequest(page: 1, pageSize: 2),
      );

      expect(page.items.length, 2);
      expect(page.totalCount, 5);
      expect(page.hasNextPage, isTrue);
      expect(repo.keywordPageRequests.single.pageSize, 2);
    },
  );
}
