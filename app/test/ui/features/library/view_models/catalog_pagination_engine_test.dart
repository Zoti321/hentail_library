import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_pagination_engine.dart';
import 'package:test/test.dart';

PagedResult<String> _pageResult({
  required int page,
  int pageSize = 10,
  int totalCount = 50,
}) {
  return PagedResult<String>(
    items: <String>['item-$page'],
    page: page,
    pageSize: pageSize,
    totalCount: totalCount,
  );
}

void main() {
  late CatalogPaginationEngine engine;

  setUp(() {
    engine = CatalogPaginationEngine();
  });

  test('syncQueryKey resets page when query changes', () {
    expect(engine.syncQueryKey(('a', 1)), isFalse);
    engine.setPage(3);
    expect(engine.pageIndex, 3);

    expect(engine.syncQueryKey(('b', 1)), isTrue);
    expect(engine.pageIndex, 1);
  });

  test('syncQueryKey does not reset on first key', () {
    engine.setPage(4);
    expect(engine.syncQueryKey(('a', 1)), isFalse);
    expect(engine.pageIndex, 4);
  });

  test('navigation methods return false at boundaries', () {
    expect(engine.goToPreviousPage(), isFalse);
    expect(engine.goToFirstPage(), isFalse);
    expect(engine.goToNextPage(3), isTrue);
    expect(engine.goToNextPage(3), isTrue);
    expect(engine.goToNextPage(3), isFalse);
    expect(engine.goToLastPage(3), isFalse);
    expect(engine.goToPreviousPage(), isTrue);
    expect(engine.pageIndex, 2);
    expect(engine.setPage(3), isTrue);
    expect(engine.setPage(3), isFalse);
    expect(engine.setPage(0), isFalse);
  });

  test('refresh clears query key and resets page', () {
    engine.syncQueryKey(('a', 1));
    engine.setPage(2);

    expect(engine.refresh(), isTrue);
    expect(engine.pageIndex, 1);

    engine.setPage(4);
    engine.syncQueryKey(('a', 1));
    engine.setPage(2);
    expect(engine.syncQueryKey(('b', 1)), isTrue);
    expect(engine.pageIndex, 1);
  });

  test('refresh returns false when already on first page', () {
    expect(engine.refresh(), isFalse);
    expect(engine.pageIndex, 1);
  });

  test('fetchPage syncs page index from result', () async {
    engine.setPage(4);
    final PagedResult<String> result = await engine.fetchPage<String>(
      pageSize: 10,
      fetch: (_) async => _pageResult(page: 2),
    );

    expect(result.page, 2);
    expect(engine.pageIndex, 2);
  });

  test('fetchPage uses current page index in request', () async {
    engine.setPage(3);
    PageRequest? captured;
    await engine.fetchPage<String>(
      pageSize: 25,
      fetch: (PageRequest request) async {
        captured = request;
        return _pageResult(page: 3);
      },
    );

    expect(captured, pageRequest(page: 3, pageSize: 25));
  });
}
