/// One slot in the desktop page-number strip (MUI [usePagination] page items).
sealed class Md3ePaginationWindowItem {
  const Md3ePaginationWindowItem();

  const factory Md3ePaginationWindowItem.page(int page) =
      Md3ePaginationWindowPage._;

  const factory Md3ePaginationWindowItem.ellipsis() =
      Md3ePaginationWindowEllipsis._;

  const factory Md3ePaginationWindowItem.empty() =
      Md3ePaginationWindowEmpty._;
}

final class Md3ePaginationWindowPage extends Md3ePaginationWindowItem {
  const Md3ePaginationWindowPage._(this.page);

  final int page;
}

final class Md3ePaginationWindowEllipsis extends Md3ePaginationWindowItem {
  const Md3ePaginationWindowEllipsis._();
}

/// Placeholder slot so the strip width stays constant while paging.
final class Md3ePaginationWindowEmpty extends Md3ePaginationWindowItem {
  const Md3ePaginationWindowEmpty._();
}

/// MUI defaults: [boundaryCount] and [siblingCount] (see usePagination.js).
class Md3ePaginationSiblingConfig {
  const Md3ePaginationSiblingConfig({
    required this.boundaryCount,
    required this.siblingCount,
  });

  final int boundaryCount;
  final int siblingCount;

  static const Md3ePaginationSiblingConfig muiDefault =
      Md3ePaginationSiblingConfig(boundaryCount: 1, siblingCount: 1);

  static const Md3ePaginationSiblingConfig compact =
      Md3ePaginationSiblingConfig(boundaryCount: 1, siblingCount: 0);
}

List<int> _md3ePaginationRange(int start, int end) {
  if (end < start) {
    return const <int>[];
  }
  return List<int>.generate(end - start + 1, (int index) => start + index);
}

/// Page-number items only (no first/prev/next/last), ported from MUI
/// `usePagination`.
List<Md3ePaginationWindowItem> md3eBuildPaginationPageWindow({
  required int currentPage,
  required int totalPages,
  Md3ePaginationSiblingConfig config = Md3ePaginationSiblingConfig.muiDefault,
}) {
  assert(currentPage >= 1 && currentPage <= totalPages);
  final int page = currentPage;
  final int count = totalPages;
  final int boundaryCount = config.boundaryCount;
  final int siblingCount = config.siblingCount;

  final List<int> startPages = _md3ePaginationRange(
    1,
    boundaryCount < count ? boundaryCount : count,
  );
  final List<int> endPages = _md3ePaginationRange(
    count - boundaryCount + 1 > boundaryCount + 1
        ? count - boundaryCount + 1
        : boundaryCount + 1,
    count,
  );

  final int siblingsStart = _max(
    _min(
      page - siblingCount,
      count - boundaryCount - siblingCount * 2 - 1,
    ),
    boundaryCount + 2,
  );

  final int siblingsEnd = _min(
    _max(
      page + siblingCount,
      boundaryCount + siblingCount * 2 + 2,
    ),
    count - boundaryCount - 1,
  );

  final List<Md3ePaginationWindowItem> items = <Md3ePaginationWindowItem>[];

  for (final int startPage in startPages) {
    items.add(Md3ePaginationWindowItem.page(startPage));
  }

  if (siblingsStart > boundaryCount + 2) {
    items.add(const Md3ePaginationWindowItem.ellipsis());
  } else if (boundaryCount + 1 < count - boundaryCount) {
    items.add(Md3ePaginationWindowItem.page(boundaryCount + 1));
  }

  for (final int siblingPage in _md3ePaginationRange(siblingsStart, siblingsEnd)) {
    items.add(Md3ePaginationWindowItem.page(siblingPage));
  }

  if (siblingsEnd < count - boundaryCount - 1) {
    items.add(const Md3ePaginationWindowItem.ellipsis());
  } else if (count - boundaryCount > boundaryCount) {
    items.add(Md3ePaginationWindowItem.page(count - boundaryCount));
  }

  for (final int endPage in endPages) {
    items.add(Md3ePaginationWindowItem.page(endPage));
  }

  return _dedupeAdjacentPageItems(items);
}

/// Pads [items] to [slotCount] with empty slots (centered) for a stable strip.
List<Md3ePaginationWindowItem> md3ePadPaginationPageWindow(
  List<Md3ePaginationWindowItem> items, {
  required int slotCount,
}) {
  if (items.length >= slotCount) {
    return items;
  }
  final int leading = (slotCount - items.length) ~/ 2;
  final int trailing = slotCount - items.length - leading;
  return <Md3ePaginationWindowItem>[
    for (int i = 0; i < leading; i++) const Md3ePaginationWindowItem.empty(),
    ...items,
    for (int i = 0; i < trailing; i++) const Md3ePaginationWindowItem.empty(),
  ];
}

/// Max page-item count for a large [count] (strip width constant while paging).
int md3ePaginationFixedPageSlotCount(Md3ePaginationSiblingConfig config) {
  const int sampleCount = 999;
  int maxItems = 0;
  for (int page = 1; page <= sampleCount; page++) {
    final int length = md3eBuildPaginationPageWindow(
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

List<Md3ePaginationWindowItem> _dedupeAdjacentPageItems(
  List<Md3ePaginationWindowItem> items,
) {
  final List<Md3ePaginationWindowItem> deduped = <Md3ePaginationWindowItem>[];
  for (final Md3ePaginationWindowItem item in items) {
    if (item is Md3ePaginationWindowPage &&
        deduped.isNotEmpty &&
        deduped.last is Md3ePaginationWindowPage &&
        (deduped.last as Md3ePaginationWindowPage).page == item.page) {
      continue;
    }
    deduped.add(item);
  }
  return deduped;
}

int _min(int a, int b) => a < b ? a : b;

int _max(int a, int b) => a > b ? a : b;
