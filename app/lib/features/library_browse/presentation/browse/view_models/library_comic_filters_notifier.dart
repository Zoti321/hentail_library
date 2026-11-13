import 'package:hentai_library/features/library_browse/domain/browse/library_comic_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/library_browse_preferences_provider.dart';

import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_needs_metadata_only.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_tri_state_pick.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/browse_library_scope_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_catalog_query_assembly.dart';

part 'library_comic_filters_notifier.g.dart';

const ComicCatalogQueryAssembly _comicProjection = ComicCatalogQueryAssembly();

/// Comics Tab 的 Library browse preference（筛选 + 排序）唯一事实来源。
///
/// 持有持久化偏好（年龄、媒体类型、标签、作者、仅待补元数据、按系列分组、排序）
/// 与会话级维度（语言 include-set、原作/角色三态）。持久化经注入仓储执行。
/// 派生 [libraryComicFilterQueryProvider] 供 Rust 查询消费。
@Riverpod(keepAlive: true)
class LibraryComicFiltersNotifier extends _$LibraryComicFiltersNotifier {
  LibraryBrowsePreferencesRepository get _preferences =>
      ref.read(libraryBrowsePreferencesRepositoryProvider);
  @override
  Future<LibraryComicBrowsePreferences> build() =>
      _preferences.loadComicFilters();

  void _apply(LibraryComicBrowsePreferences updated) {
    state = AsyncData<LibraryComicBrowsePreferences>(updated);
  }

  Future<void> setAgeRestriction(LibraryAgeRestrictionFilter filter) async {
    _apply((await future).copyWith(ageRestriction: filter));
    await _preferences.saveComicAgeRestriction(filter);
  }

  Future<void> toggleAgeRestrictionOption(
    LibraryAgeRestrictionFilter option,
  ) async {
    final LibraryAgeRestrictionFilter existing = (await future).ageRestriction;
    await setAgeRestriction(
      existing == option ? LibraryAgeRestrictionFilter.unrestricted : option,
    );
  }

  Future<void> toggleMediaType(LibraryMediaTypeFilterOption option) async {
    final LibraryComicBrowsePreferences current = await future;
    final LibraryMediaTypeFilterSelection updated = current.mediaTypeFilter
        .withToggled(option);
    _apply(current.copyWith(mediaTypeFilter: updated));
    await _preferences.saveComicMediaTypes(updated);
  }

  Future<void> clearMediaType() async {
    _apply(
      (await future).copyWith(
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
      ),
    );
    await _preferences.saveComicMediaTypes(
      const LibraryMediaTypeFilterSelection(),
    );
  }

  Future<void> toggleTag(String name) async {
    await _updateMetadataSelection(
      tags: true,
      transform: (LibraryMetadataFilterSelection current) =>
          current.withToggled(name),
    );
  }

  Future<void> setTagIncludeMode(LibraryMetadataIncludeMode mode) async {
    await _updateMetadataSelection(
      tags: true,
      transform: (LibraryMetadataFilterSelection current) =>
          current.withIncludeMode(mode),
    );
  }

  Future<void> clearTag() async {
    await _updateMetadataSelection(
      tags: true,
      transform: (LibraryMetadataFilterSelection current) => current.cleared(),
    );
  }

  Future<void> toggleAuthor(String name) async {
    await _updateMetadataSelection(
      tags: false,
      transform: (LibraryMetadataFilterSelection current) =>
          current.withToggled(name),
    );
  }

  Future<void> setAuthorIncludeMode(LibraryMetadataIncludeMode mode) async {
    await _updateMetadataSelection(
      tags: false,
      transform: (LibraryMetadataFilterSelection current) =>
          current.withIncludeMode(mode),
    );
  }

  Future<void> clearAuthor() async {
    await _updateMetadataSelection(
      tags: false,
      transform: (LibraryMetadataFilterSelection current) => current.cleared(),
    );
  }

  Future<void> _updateMetadataSelection({
    required bool tags,
    required LibraryMetadataFilterSelection Function(
      LibraryMetadataFilterSelection current,
    )
    transform,
  }) async {
    final LibraryComicBrowsePreferences current = await future;
    final LibraryMetadataFilterSelection updated = transform(
      tags ? current.tagFilter : current.authorFilter,
    );
    _apply(
      tags
          ? current.copyWith(tagFilter: updated)
          : current.copyWith(authorFilter: updated),
    );
    if (tags) {
      await _preferences.saveComicTags(updated);
    } else {
      await _preferences.saveComicAuthors(updated);
    }
  }

  Future<void> toggleIncludeSet(LibraryIncludeSetKind kind, String name) async {
    final LibraryComicBrowsePreferences current = await future;
    final Set<String> updated = Set<String>.of(current.includeSetFor(kind));
    if (!updated.add(name)) {
      updated.remove(name);
    }
    _apply(_withIncludeSet(current, kind, updated));
  }

  Future<void> clearIncludeSet(LibraryIncludeSetKind kind) async {
    _apply(_withIncludeSet(await future, kind, const <String>{}));
  }

  LibraryComicBrowsePreferences _withIncludeSet(
    LibraryComicBrowsePreferences current,
    LibraryIncludeSetKind kind,
    Set<String> value,
  ) {
    return switch (kind) {
      LibraryIncludeSetKind.language => current.copyWith(languageFilter: value),
    };
  }

  Future<void> toggleParody(String name) async {
    final LibraryComicBrowsePreferences current = await future;
    _apply(
      current.copyWith(parodyFilter: current.parodyFilter.withToggled(name)),
    );
  }

  Future<void> setParodyIncludeMode(LibraryMetadataIncludeMode mode) async {
    final LibraryComicBrowsePreferences current = await future;
    _apply(
      current.copyWith(
        parodyFilter: current.parodyFilter.withIncludeMode(mode),
      ),
    );
  }

  Future<void> toggleCharacter(String name) async {
    final LibraryComicBrowsePreferences current = await future;
    _apply(
      current.copyWith(
        characterFilter: current.characterFilter.withToggled(name),
      ),
    );
  }

  Future<void> setCharacterIncludeMode(LibraryMetadataIncludeMode mode) async {
    final LibraryComicBrowsePreferences current = await future;
    _apply(
      current.copyWith(
        characterFilter: current.characterFilter.withIncludeMode(mode),
      ),
    );
  }

  Future<void> setNeedsMetadataOnly(bool enabled) async {
    _apply((await future).copyWith(needsMetadataOnly: enabled));
    await _preferences.saveNeedsMetadataOnly(enabled);
  }

  Future<void> setGrouping(LibraryComicGrouping grouping) async {
    _apply((await future).copyWith(grouping: grouping));
    await _preferences.saveComicGrouping(grouping);
  }

  Future<void> setSortField(LibraryComicSortField field) async {
    final LibraryComicSortOption existing = (await future).sortOption;
    final LibraryComicSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibraryComicSortOption(
            field: field,
            descending: field == LibraryComicSortField.readAt,
          );
    _apply((await future).copyWith(sortOption: next));
    await _preferences.saveComicSort(next);
  }

  /// 清空当前 Library 的全部 Comics 筛选与排序（会话级维度一并清空）。
  Future<void> resetAll() async {
    await _preferences.resetComicFilters();
    _apply(LibraryComicBrowsePreferences.defaults);
  }
}

/// Comics Tab 筛选意图派生出的 Rust 查询 filter（含关键词）。
final Provider<LibraryComicFilter> libraryComicFilterQueryProvider =
    Provider<LibraryComicFilter>((Ref ref) {
      final LibraryComicBrowsePreferences filters =
          ref.watch(libraryComicFiltersProvider).value ??
          LibraryComicBrowsePreferences.defaults;
      final String keyword = ref.watch(
        libraryQueryIntentProvider.select(
          (LibraryQueryIntent intent) => intent.keyword,
        ),
      );
      final String? libraryId = ref.watch(browseLibraryIdProvider);
      return _comicProjection.buildListFilter(
        ageRestriction: filters.ageRestriction,
        mediaTypeFilter: filters.mediaTypeFilter,
        tagFilter: filters.tagFilter,
        authorFilter: filters.authorFilter,
        languages: filters.languageFilter,
        parodyFilter: filters.parodyFilter,
        characterFilter: filters.characterFilter,
        needsMetadataOnly: filters.needsMetadataOnly,
        keyword: keyword,
        libraryId: libraryId,
      );
    });

/// Comics Tab 是否含有非默认筛选 / 排序。
final Provider<bool> libraryComicFiltersIsCustomizedProvider = Provider<bool>((
  Ref ref,
) {
  final LibraryComicBrowsePreferences filters =
      ref.watch(libraryComicFiltersProvider).value ??
      LibraryComicBrowsePreferences.defaults;
  if (filters.ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
      filters.mediaTypeFilter.isActive ||
      filters.tagFilter.isActive ||
      filters.authorFilter.isActive ||
      filters.languageFilter.isNotEmpty ||
      filters.parodyFilter.isActive ||
      filters.characterFilter.isActive ||
      filters.grouping != LibraryComicGrouping.defaultValue ||
      filters.needsMetadataOnly != LibraryNeedsMetadataOnly.defaultValue) {
    return true;
  }
  return filters.sortOption.field != kLibraryDefaultSortOption.field ||
      filters.sortOption.descending != kLibraryDefaultSortOption.descending;
});
