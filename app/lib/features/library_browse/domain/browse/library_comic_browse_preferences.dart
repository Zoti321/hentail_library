import 'package:collection/collection.dart';
import 'package:hentai_library/features/comic/public/library_comic_browse_rules.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_needs_metadata_only.dart';

/// Comics 默认排序（标题升序）。
final LibraryComicSortOption kLibraryDefaultSortOption =
    LibraryComicSortOption();

/// 会话级 include-only 筛选维度（不落盘，仅在浏览期间保留）。
enum LibraryIncludeSetKind { language }

/// Comics Tab 的完整 Library browse preference（筛选 + 排序意图）。
///
/// 单一不可变值对象：Comics 目录、筛选抽屉、重置与选择模式都只依赖它，
/// Persistent and session-only dimensions share this value; repositories persist only the former.
class LibraryComicBrowsePreferences {
  LibraryComicBrowsePreferences({
    required this.ageRestriction,
    required this.mediaTypeFilter,
    required this.tagFilter,
    required this.authorFilter,
    required this.needsMetadataOnly,
    required this.grouping,
    required this.sortOption,
    this.languageFilter = const <String>{},
    this.parodyFilter = const LibraryMetadataFilterSelection(),
    this.characterFilter = const LibraryMetadataFilterSelection(),
  });

  /// 默认（未筛选）状态；加载完成前的占位值。
  static final LibraryComicBrowsePreferences defaults =
      LibraryComicBrowsePreferences(
        ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
        tagFilter: const LibraryMetadataFilterSelection(),
        authorFilter: const LibraryMetadataFilterSelection(),
        needsMetadataOnly: LibraryNeedsMetadataOnly.defaultValue,
        grouping: LibraryComicGrouping.defaultValue,
        sortOption: LibraryComicSortOption(),
      );

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibraryMediaTypeFilterSelection mediaTypeFilter;
  final LibraryMetadataFilterSelection tagFilter;
  final LibraryMetadataFilterSelection authorFilter;
  final bool needsMetadataOnly;
  final LibraryComicGrouping grouping;
  final LibraryComicSortOption sortOption;

  /// 会话级 include-only 维度（语言闭集）。
  final Set<String> languageFilter;

  /// 会话级原作 / 角色三态筛选（不落盘）。
  final LibraryMetadataFilterSelection parodyFilter;
  final LibraryMetadataFilterSelection characterFilter;

  Set<String> includeSetFor(LibraryIncludeSetKind kind) => switch (kind) {
    LibraryIncludeSetKind.language => languageFilter,
  };

  LibraryComicBrowsePreferences copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibraryMediaTypeFilterSelection? mediaTypeFilter,
    LibraryMetadataFilterSelection? tagFilter,
    LibraryMetadataFilterSelection? authorFilter,
    bool? needsMetadataOnly,
    LibraryComicGrouping? grouping,
    LibraryComicSortOption? sortOption,
    Set<String>? languageFilter,
    LibraryMetadataFilterSelection? parodyFilter,
    LibraryMetadataFilterSelection? characterFilter,
  }) {
    return LibraryComicBrowsePreferences(
      ageRestriction: ageRestriction ?? this.ageRestriction,
      mediaTypeFilter: mediaTypeFilter ?? this.mediaTypeFilter,
      tagFilter: tagFilter ?? this.tagFilter,
      authorFilter: authorFilter ?? this.authorFilter,
      needsMetadataOnly: needsMetadataOnly ?? this.needsMetadataOnly,
      grouping: grouping ?? this.grouping,
      sortOption: sortOption ?? this.sortOption,
      languageFilter: languageFilter ?? this.languageFilter,
      parodyFilter: parodyFilter ?? this.parodyFilter,
      characterFilter: characterFilter ?? this.characterFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LibraryComicBrowsePreferences &&
            other.ageRestriction == ageRestriction &&
            const SetEquality<LibraryMediaTypeFilterOption>().equals(
              other.mediaTypeFilter.selected,
              mediaTypeFilter.selected,
            ) &&
            other.tagFilter == tagFilter &&
            other.authorFilter == authorFilter &&
            other.needsMetadataOnly == needsMetadataOnly &&
            other.grouping == grouping &&
            other.sortOption == sortOption &&
            const SetEquality<String>().equals(
              other.languageFilter,
              languageFilter,
            ) &&
            other.parodyFilter == parodyFilter &&
            other.characterFilter == characterFilter;
  }

  @override
  int get hashCode => Object.hash(
    ageRestriction,
    Object.hashAllUnordered(mediaTypeFilter.selected),
    tagFilter,
    authorFilter,
    needsMetadataOnly,
    grouping,
    sortOption,
    Object.hashAllUnordered(languageFilter),
    parodyFilter,
    characterFilter,
  );
}
