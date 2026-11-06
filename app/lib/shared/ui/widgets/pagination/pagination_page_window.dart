/// One slot in the desktop page-number strip (MUI [usePagination] page items).
sealed class PaginationWindowItem {
  const PaginationWindowItem();

  const factory PaginationWindowItem.page(int page) = PaginationWindowPage._;

  const factory PaginationWindowItem.ellipsis() = PaginationWindowEllipsis._;

  const factory PaginationWindowItem.empty() = PaginationWindowEmpty._;
}

final class PaginationWindowPage extends PaginationWindowItem {
  const PaginationWindowPage._(this.page);

  final int page;
}

final class PaginationWindowEllipsis extends PaginationWindowItem {
  const PaginationWindowEllipsis._();
}

/// Placeholder slot so the strip width stays constant while paging.
final class PaginationWindowEmpty extends PaginationWindowItem {
  const PaginationWindowEmpty._();
}

/// MUI defaults: [boundaryCount] and [siblingCount] (see usePagination.js).
class PaginationSiblingConfig {
  const PaginationSiblingConfig({
    required this.boundaryCount,
    required this.siblingCount,
  });

  final int boundaryCount;
  final int siblingCount;

  static const PaginationSiblingConfig muiDefault = PaginationSiblingConfig(
    boundaryCount: 1,
    siblingCount: 1,
  );

  static const PaginationSiblingConfig compact = PaginationSiblingConfig(
    boundaryCount: 1,
    siblingCount: 0,
  );
}

List<int> PaginationRange(int start, int end) {
  if (end < start) {
    return const <int>[];
  }
  return List<int>.generate(end - start + 1, (int index) => start + index);
}

/// Page-number items only (no first/prev/next/last), ported from MUI
/// `usePagination`.
List<PaginationWindowItem> buildPaginationPageWindow({
  required int currentPage,
  required int totalPages,
  PaginationSiblingConfig config = PaginationSiblingConfig.muiDefault,
}) {
  assert(currentPage >= 1 && currentPage <= totalPages);
  final int page = currentPage;
  final int count = totalPages;
  final int boundaryCount = config.boundaryCount;
  final int siblingCount = config.siblingCount;

  final List<int> startPages = PaginationRange(
    1,
    boundaryCount < count ? boundaryCount : count,
  );
  final List<int> endPages = PaginationRange(
    count - boundaryCount + 1 > boundaryCount + 1
        ? count - boundaryCount + 1
        : boundaryCount + 1,
    count,
  );

  final int siblingsStart = _max(
    _min(page - siblingCount, count - boundaryCount - siblingCount * 2 - 1),
    boundaryCount + 2,
  );

  final int siblingsEnd = _min(
    _max(page + siblingCount, boundaryCount + siblingCount * 2 + 2),
    count - boundaryCount - 1,
  );

  final List<PaginationWindowItem> items = <PaginationWindowItem>[];

  for (final int startPage in startPages) {
    items.add(PaginationWindowItem.page(startPage));
  }

  if (siblingsStart > boundaryCount + 2) {
    items.add(const PaginationWindowItem.ellipsis());
  } else if (boundaryCount + 1 < count - boundaryCount) {
    items.add(PaginationWindowItem.page(boundaryCount + 1));
  }

  for (final int siblingPage in PaginationRange(siblingsStart, siblingsEnd)) {
    items.add(PaginationWindowItem.page(siblingPage));
  }

  if (siblingsEnd < count - boundaryCount - 1) {
    items.add(const PaginationWindowItem.ellipsis());
  } else if (count - boundaryCount > boundaryCount) {
    items.add(PaginationWindowItem.page(count - boundaryCount));
  }

  for (final int endPage in endPages) {
    items.add(PaginationWindowItem.page(endPage));
  }

  return _dedupeAdjacentPageItems(items);
}

/// Pads [items] to [slotCount] with empty slots (centered) for a stable strip.
List<PaginationWindowItem> padPaginationPageWindow(
  List<PaginationWindowItem> items, {
  required int slotCount,
}) {
  if (items.length >= slotCount) {
    return items;
  }
  final int leading = (slotCount - items.length) ~/ 2;
  final int trailing = slotCount - items.length - leading;
  return <PaginationWindowItem>[
    for (int i = 0; i < leading; i++) const PaginationWindowItem.empty(),
    ...items,
    for (int i = 0; i < trailing; i++) const PaginationWindowItem.empty(),
  ];
}

/// Max page-item count for a large [count] (strip width constant while paging).
int paginationFixedPageSlotCount(PaginationSiblingConfig config) {
  const int sampleCount = 999;
  int maxItems = 0;
  for (int page = 1; page <= sampleCount; page++) {
    final int length = buildPaginationPageWindow(
      currentPage: page,
      totalPages: sampleCount,
      config: config,
    ).length;
    if (length > maxItems) {
      maxItems = length;
    }
  }
  return maxItems;
}

List<PaginationWindowItem> _dedupeAdjacentPageItems(
  List<PaginationWindowItem> items,
) {
  final List<PaginationWindowItem> deduped = <PaginationWindowItem>[];
  for (final PaginationWindowItem item in items) {
    if (item is PaginationWindowPage &&
        deduped.isNotEmpty &&
        deduped.last is PaginationWindowPage &&
        (deduped.last as PaginationWindowPage).page == item.page) {
      continue;
    }
    deduped.add(item);
  }
  return deduped;
}

int _min(int a, int b) => a < b ? a : b;

int _max(int a, int b) => a > b ? a : b;
