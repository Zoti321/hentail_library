import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/entities/reorderable_animation_config.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';

const Duration kLibraryCatalogSortFlipDuration = Duration(milliseconds: 400);

/// 分页、筛选、每页条数变化时用于关闭 FLIP 动画的键（不含排序字段）。
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

bool nextLibraryCatalogSortFlipAnimationEnabled({
  required bool current,
  required bool sortChanged,
  required bool suppressChanged,
}) {
  if (sortChanged) {
    return true;
  }
  if (suppressChanged) {
    return false;
  }
  return current;
}

ReorderableAnimationConfig libraryCatalogSortFlipAnimationConfig({
  required bool enableAnimations,
}) {
  return ReorderableAnimationConfig(
    positionChangeDuration: kLibraryCatalogSortFlipDuration,
    positionChangeCurve: Curves.ease,
    defaultAnimationCurve: Curves.ease,
    fadeInDuration: Duration.zero,
    enableAnimations: enableAnimations,
  );
}
