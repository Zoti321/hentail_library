import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:test/test.dart';

void main() {
  test('stablePagedTotalCount keeps previous total during reload', () {
    const AsyncValue<PagedResult<Comic>> loaded = AsyncData(
      PagedResult<Comic>(
        items: <Comic>[],
        totalCount: 42,
        page: 1,
        pageSize: 50,
      ),
    );

    expect(stablePagedTotalCount(loaded), 42);
    expect(stablePagedTotalCount(const AsyncLoading<PagedResult<Comic>>()), 0);
  });
}
