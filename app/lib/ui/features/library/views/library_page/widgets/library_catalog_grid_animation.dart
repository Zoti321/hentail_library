import 'package:flutter/material.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';

/// 库页翻页动效时长（对齐桌面短动效 180–220 ms）。
const Duration kLibraryCatalogPageTransitionDuration = Duration(
  milliseconds: 200,
);

enum LibraryCatalogPageTransitionDirection { none, forward, backward }

/// 分页、筛选、每页条数变化时用于区分「仅翻页」与「目录重载」的键。
@immutable
class LibraryCatalogGridSuppressAnimationKey {
  const LibraryCatalogGridSuppressAnimationKey({
    required this.keyword,
    required this.ageRestriction,
    required this.page,
    required this.pageSize,
  });

  final String keyword;
  final LibraryAgeRestrictionFilter ageRestriction;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is LibraryCatalogGridSuppressAnimationKey &&
        other.keyword == keyword &&
        other.ageRestriction == ageRestriction &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(keyword, ageRestriction, page, pageSize);
}

/// 仅页码变化（非筛选、每页条数）时返回 true。
bool libraryCatalogGridPageOnlyChanged({
  required LibraryCatalogGridSuppressAnimationKey previous,
  required LibraryCatalogGridSuppressAnimationKey next,
}) {
  return previous.page != next.page &&
      previous.keyword == next.keyword &&
      previous.ageRestriction == next.ageRestriction &&
      previous.pageSize == next.pageSize;
}

LibraryCatalogPageTransitionDirection libraryCatalogPageTransitionDirection({
  required int previousPage,
  required int nextPage,
}) {
  if (previousPage == nextPage) {
    return LibraryCatalogPageTransitionDirection.none;
  }
  return nextPage > previousPage
      ? LibraryCatalogPageTransitionDirection.forward
      : LibraryCatalogPageTransitionDirection.backward;
}
