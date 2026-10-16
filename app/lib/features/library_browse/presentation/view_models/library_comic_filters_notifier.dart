import 'package:flutter/foundation.dart';
import 'package:hentai_library/features/library_browse/domain/author_filter_preference_migration.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/library_comic_filter.dart';
import 'package:hentai_library/features/library_browse/domain/library_comic_projection.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/features/library_browse/domain/library_expand_by_series.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/library_needs_metadata_only.dart';
import 'package:hentai_library/features/library_browse/domain/library_tri_state_pick.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_comic_filters_notifier.g.dart';

/// Comics 默认排序（标题升序）。
final LibraryComicSortOption kLibraryDefaultSortOption =
    LibraryComicSortOption();

/// 会话级 include-only 筛选维度（不落盘，仅在浏览期间保留）。
enum LibraryIncludeSetKind { language, parody, character }

/// Comics Tab 的完整 Library browse preference（筛选 + 排序意图）。
///
/// 单一不可变值对象：Comics 目录、筛选抽屉、重置与选择模式都只依赖它，
/// 新增一个筛选维度只需改动此处与 [LibraryComicFiltersNotifier]。
class LibraryComicFiltersState {
  LibraryComicFiltersState({
    required this.ageRestriction,
    required this.mediaTypeFilter,
    required this.tagFilter,
    required this.authorFilter,
    required this.needsMetadataOnly,
    required this.expandBySeries,
    required this.sortOption,
    this.languageFilter = const <String>{},
    this.parodyFilter = const <String>{},
    this.characterFilter = const <String>{},
  });

  /// 默认（未筛选）状态；加载完成前的占位值。
  static final LibraryComicFiltersState defaults = LibraryComicFiltersState(
    ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
    mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
    tagFilter: const LibraryMetadataFilterSelection(),
    authorFilter: const LibraryMetadataFilterSelection(),
    needsMetadataOnly: LibraryNeedsMetadataOnly.defaultValue,
    expandBySeries: LibraryExpandBySeries.defaultValue,
    sortOption: LibraryComicSortOption(),
  );

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibraryMediaTypeFilterSelection mediaTypeFilter;
  final LibraryMetadataFilterSelection tagFilter;
  final LibraryMetadataFilterSelection authorFilter;
  final bool needsMetadataOnly;
  final bool expandBySeries;
  final LibraryComicSortOption sortOption;

  /// 会话级 include-only 维度。
  final Set<String> languageFilter;
  final Set<String> parodyFilter;
  final Set<String> characterFilter;

  Set<String> includeSetFor(LibraryIncludeSetKind kind) => switch (kind) {
    LibraryIncludeSetKind.language => languageFilter,
    LibraryIncludeSetKind.parody => parodyFilter,
    LibraryIncludeSetKind.character => characterFilter,
  };

  LibraryComicFiltersState copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibraryMediaTypeFilterSelection? mediaTypeFilter,
    LibraryMetadataFilterSelection? tagFilter,
    LibraryMetadataFilterSelection? authorFilter,
    bool? needsMetadataOnly,
    bool? expandBySeries,
    LibraryComicSortOption? sortOption,
    Set<String>? languageFilter,
    Set<String>? parodyFilter,
    Set<String>? characterFilter,
  }) {
    return LibraryComicFiltersState(
      ageRestriction: ageRestriction ?? this.ageRestriction,
      mediaTypeFilter: mediaTypeFilter ?? this.mediaTypeFilter,
      tagFilter: tagFilter ?? this.tagFilter,
      authorFilter: authorFilter ?? this.authorFilter,
      needsMetadataOnly: needsMetadataOnly ?? this.needsMetadataOnly,
      expandBySeries: expandBySeries ?? this.expandBySeries,
      sortOption: sortOption ?? this.sortOption,
      languageFilter: languageFilter ?? this.languageFilter,
      parodyFilter: parodyFilter ?? this.parodyFilter,
      characterFilter: characterFilter ?? this.characterFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LibraryComicFiltersState &&
            other.ageRestriction == ageRestriction &&
            setEquals(
              other.mediaTypeFilter.selected,
              mediaTypeFilter.selected,
            ) &&
            other.tagFilter == tagFilter &&
            other.authorFilter == authorFilter &&
            other.needsMetadataOnly == needsMetadataOnly &&
            other.expandBySeries == expandBySeries &&
            other.sortOption == sortOption &&
            setEquals(other.languageFilter, languageFilter) &&
            setEquals(other.parodyFilter, parodyFilter) &&
            setEquals(other.characterFilter, characterFilter);
  }

  @override
  int get hashCode => Object.hash(
    ageRestriction,
    Object.hashAllUnordered(mediaTypeFilter.selected),
    tagFilter,
    authorFilter,
    needsMetadataOnly,
    expandBySeries,
    sortOption,
    Object.hashAllUnordered(languageFilter),
    Object.hashAllUnordered(parodyFilter),
    Object.hashAllUnordered(characterFilter),
  );
}

/// 年龄限制存储键：Comics 归本模块，Series 归
/// [LibrarySeriesFiltersNotifier]。
const String kLibraryComicsAgeRestrictionStorageKey =
    'library_age_restriction_filter_comics';
const String kLibrarySeriesAgeRestrictionStorageKey =
    'library_age_restriction_filter_series';

/// 旧版单键年龄限制一次性迁移到 Comics / Series 双键。
Future<void> migrateLegacyLibraryAgeRestriction(SharedPreferences prefs) async {
  if (!prefs.containsKey(kLibraryComicsAgeRestrictionStorageKey) &&
      !prefs.containsKey(kLibrarySeriesAgeRestrictionStorageKey) &&
      prefs.containsKey(LibraryAgeRestrictionFilter.storageKey)) {
    final LibraryAgeRestrictionFilter legacy =
        LibraryAgeRestrictionFilter.fromStorage(
          prefs.getString(LibraryAgeRestrictionFilter.storageKey),
        );
    if (legacy != LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.setString(
        kLibraryComicsAgeRestrictionStorageKey,
        legacy.name,
      );
      await prefs.setString(
        kLibrarySeriesAgeRestrictionStorageKey,
        legacy.name,
      );
    }
    await prefs.remove(LibraryAgeRestrictionFilter.storageKey);
  }
}

const LibraryComicProjection _comicProjection = LibraryComicProjection();

/// Comics Tab 的 Library browse preference（筛选 + 排序）唯一事实来源。
///
/// 持有持久化偏好（年龄、媒体类型、标签、作者、仅待补元数据、按系列展开、排序）
/// 与会话级 include-set（语言 / parody / character）；命令方法负责写回
/// SharedPreferences。派生 [libraryComicFilterQueryProvider] 供 Rust 查询消费。
@Riverpod(keepAlive: true)
class LibraryComicFiltersNotifier extends _$LibraryComicFiltersNotifier {
  static const String _ageStorageKey = kLibraryComicsAgeRestrictionStorageKey;
  static const String _mediaTypeStorageKey = 'library_media_type_filter_comics';
  static const String _tagIncludeStorageKey = 'library_tag_filter_include';
  static const String _tagExcludeStorageKey = 'library_tag_filter_exclude';
  static const String _tagIncludeModeStorageKey =
      'library_tag_filter_include_mode';
  static const String _authorIncludeStorageKey =
      'library_author_filter_include_ids';
  static const String _authorExcludeStorageKey =
      'library_author_filter_exclude_ids';
  static const String _authorIncludeModeStorageKey =
      'library_author_filter_include_mode';
  static const String _legacyAuthorIncludeStorageKey =
      'library_author_filter_include';
  static const String _legacyAuthorExcludeStorageKey =
      'library_author_filter_exclude';
  static const String _sortStorageKey = 'library_sort_comics';

  @override
  Future<LibraryComicFiltersState> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacyLibraryAgeRestriction(prefs);

    final List<Author> authors = await ref.read(authorRepoProvider).listAll();
    final bool hasAuthorIdKeys =
        prefs.containsKey(_authorIncludeStorageKey) ||
        prefs.containsKey(_authorExcludeStorageKey);
    final LibraryMetadataFilterSelection
    authorFilter = migrateAuthorFilterPreference(
      includeIds: hasAuthorIdKeys
          ? prefs.getStringList(_authorIncludeStorageKey)
          : null,
      excludeIds: hasAuthorIdKeys
          ? prefs.getStringList(_authorExcludeStorageKey)
          : null,
      legacyIncludeNames: prefs.getStringList(_legacyAuthorIncludeStorageKey),
      legacyExcludeNames: prefs.getStringList(_legacyAuthorExcludeStorageKey),
      includeModeName: prefs.getString(_authorIncludeModeStorageKey),
      authors: authors,
    );
    if (!hasAuthorIdKeys &&
        (prefs.containsKey(_legacyAuthorIncludeStorageKey) ||
            prefs.containsKey(_legacyAuthorExcludeStorageKey))) {
      await _writeMetadataSelection(
        prefs,
        authorFilter,
        includeKey: _authorIncludeStorageKey,
        excludeKey: _authorExcludeStorageKey,
        includeModeKey: _authorIncludeModeStorageKey,
      );
      await prefs.remove(_legacyAuthorIncludeStorageKey);
      await prefs.remove(_legacyAuthorExcludeStorageKey);
    }

    return LibraryComicFiltersState(
      ageRestriction: LibraryAgeRestrictionFilter.fromStorage(
        prefs.getString(_ageStorageKey),
      ),
      mediaTypeFilter: LibraryMediaTypeFilterSelection.fromStorage(
        prefs.getStringList(_mediaTypeStorageKey),
      ),
      tagFilter: LibraryMetadataFilterSelection.fromStorage(
        includeNames: prefs.getStringList(_tagIncludeStorageKey),
        excludeNames: prefs.getStringList(_tagExcludeStorageKey),
        includeModeName: prefs.getString(_tagIncludeModeStorageKey),
      ),
      authorFilter: authorFilter,
      needsMetadataOnly: LibraryNeedsMetadataOnly.fromStorage(
        prefs.getBool(LibraryNeedsMetadataOnly.storageKey),
      ),
      expandBySeries: LibraryExpandBySeries.fromStorage(
        prefs.getBool(LibraryExpandBySeries.storageKey),
      ),
      sortOption: _decodeComicSortOption(prefs.getString(_sortStorageKey)),
    );
  }

  void _apply(LibraryComicFiltersState updated) {
    state = AsyncData<LibraryComicFiltersState>(updated);
  }

  Future<void> setAgeRestriction(LibraryAgeRestrictionFilter filter) async {
    _apply((await future).copyWith(ageRestriction: filter));
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (filter == LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.remove(_ageStorageKey);
    } else {
      await prefs.setString(_ageStorageKey, filter.name);
    }
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
    final LibraryComicFiltersState current = await future;
    final LibraryMediaTypeFilterSelection updated = current.mediaTypeFilter
        .withToggled(option);
    _apply(current.copyWith(mediaTypeFilter: updated));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (updated.selected.isEmpty) {
      await prefs.remove(_mediaTypeStorageKey);
    } else {
      await prefs.setStringList(_mediaTypeStorageKey, updated.toStorage());
    }
  }

  Future<void> clearMediaType() async {
    _apply(
      (await future).copyWith(
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
      ),
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mediaTypeStorageKey);
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
    final LibraryComicFiltersState current = await future;
    final LibraryMetadataFilterSelection updated = transform(
      tags ? current.tagFilter : current.authorFilter,
    );
    _apply(
      tags
          ? current.copyWith(tagFilter: updated)
          : current.copyWith(authorFilter: updated),
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _writeMetadataSelection(
      prefs,
      updated,
      includeKey: tags ? _tagIncludeStorageKey : _authorIncludeStorageKey,
      excludeKey: tags ? _tagExcludeStorageKey : _authorExcludeStorageKey,
      includeModeKey: tags
          ? _tagIncludeModeStorageKey
          : _authorIncludeModeStorageKey,
    );
  }

  Future<void> _writeMetadataSelection(
    SharedPreferences prefs,
    LibraryMetadataFilterSelection selection, {
    required String includeKey,
    required String excludeKey,
    required String includeModeKey,
  }) async {
    if (!selection.isActive &&
        selection.includeMode == LibraryMetadataIncludeMode.any) {
      await prefs.remove(includeKey);
      await prefs.remove(excludeKey);
      await prefs.remove(includeModeKey);
      return;
    }
    if (selection.includeNames().isEmpty) {
      await prefs.remove(includeKey);
    } else {
      await prefs.setStringList(includeKey, selection.includeNamesToStorage());
    }
    if (selection.excludeNames().isEmpty) {
      await prefs.remove(excludeKey);
    } else {
      await prefs.setStringList(excludeKey, selection.excludeNamesToStorage());
    }
    if (selection.includeMode == LibraryMetadataIncludeMode.any) {
      await prefs.remove(includeModeKey);
    } else {
      await prefs.setString(includeModeKey, selection.includeMode.name);
    }
  }

  Future<void> toggleIncludeSet(LibraryIncludeSetKind kind, String name) async {
    final LibraryComicFiltersState current = await future;
    final Set<String> updated = Set<String>.of(current.includeSetFor(kind));
    if (!updated.add(name)) {
      updated.remove(name);
    }
    _apply(_withIncludeSet(current, kind, updated));
  }

  Future<void> clearIncludeSet(LibraryIncludeSetKind kind) async {
    _apply(_withIncludeSet(await future, kind, const <String>{}));
  }

  LibraryComicFiltersState _withIncludeSet(
    LibraryComicFiltersState current,
    LibraryIncludeSetKind kind,
    Set<String> value,
  ) {
    return switch (kind) {
      LibraryIncludeSetKind.language => current.copyWith(languageFilter: value),
      LibraryIncludeSetKind.parody => current.copyWith(parodyFilter: value),
      LibraryIncludeSetKind.character => current.copyWith(
        characterFilter: value,
      ),
    };
  }

  Future<void> setNeedsMetadataOnly(bool enabled) async {
    _apply((await future).copyWith(needsMetadataOnly: enabled));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryNeedsMetadataOnly.defaultValue) {
      await prefs.remove(LibraryNeedsMetadataOnly.storageKey);
    } else {
      await prefs.setBool(LibraryNeedsMetadataOnly.storageKey, enabled);
    }
  }

  Future<void> setExpandBySeries(bool enabled) async {
    _apply((await future).copyWith(expandBySeries: enabled));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryExpandBySeries.defaultValue) {
      await prefs.remove(LibraryExpandBySeries.storageKey);
    } else {
      await prefs.setBool(LibraryExpandBySeries.storageKey, enabled);
    }
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_isDefaultComicSort(next)) {
      await prefs.remove(_sortStorageKey);
    } else {
      await prefs.setString(_sortStorageKey, _encodeComicSortOption(next));
    }
  }

  /// 清空当前 Library 的全部 Comics 筛选与排序（会话级维度一并清空）。
  Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ageStorageKey);
    await prefs.remove(_mediaTypeStorageKey);
    await prefs.remove(_tagIncludeStorageKey);
    await prefs.remove(_tagExcludeStorageKey);
    await prefs.remove(_tagIncludeModeStorageKey);
    await prefs.remove(_authorIncludeStorageKey);
    await prefs.remove(_authorExcludeStorageKey);
    await prefs.remove(_authorIncludeModeStorageKey);
    await prefs.remove(_sortStorageKey);
    await prefs.remove(LibraryNeedsMetadataOnly.storageKey);
    await prefs.remove(LibraryExpandBySeries.storageKey);
    _apply(LibraryComicFiltersState.defaults);
  }

  static bool _isDefaultComicSort(LibraryComicSortOption option) {
    return option.field == kLibraryDefaultSortOption.field &&
        option.descending == kLibraryDefaultSortOption.descending;
  }

  static String _encodeComicSortOption(LibraryComicSortOption option) {
    return '${option.field.name},${option.descending}';
  }

  static LibraryComicSortOption _decodeComicSortOption(String? raw) {
    if (raw == null || raw.isEmpty) {
      return kLibraryDefaultSortOption;
    }
    final List<String> parts = raw.split(',');
    if (parts.length != 2) {
      return kLibraryDefaultSortOption;
    }
    final LibraryComicSortField? field = LibraryComicSortField.values
        .asNameMap()[parts[0]];
    if (field == null) {
      return kLibraryDefaultSortOption;
    }
    return LibraryComicSortOption(field: field, descending: parts[1] == 'true');
  }
}

/// Comics Tab 筛选意图派生出的 Rust 查询 filter（含关键词）。
final Provider<LibraryComicFilter> libraryComicFilterQueryProvider =
    Provider<LibraryComicFilter>((Ref ref) {
      final LibraryComicFiltersState filters =
          ref.watch(libraryComicFiltersProvider).value ??
          LibraryComicFiltersState.defaults;
      final String keyword = ref.watch(
        libraryQueryIntentProvider.select(
          (LibraryQueryIntent intent) => intent.keyword,
        ),
      );
      return _comicProjection.buildListFilter(
        ageRestriction: filters.ageRestriction,
        mediaTypeFilter: filters.mediaTypeFilter,
        tagFilter: filters.tagFilter,
        authorFilter: filters.authorFilter,
        languages: filters.languageFilter,
        parodies: filters.parodyFilter,
        characters: filters.characterFilter,
        needsMetadataOnly: filters.needsMetadataOnly,
        keyword: keyword,
      );
    });

/// Comics Tab 是否含有非默认筛选 / 排序。
final Provider<bool> libraryComicFiltersIsCustomizedProvider = Provider<bool>((
  Ref ref,
) {
  final LibraryComicFiltersState filters =
      ref.watch(libraryComicFiltersProvider).value ??
      LibraryComicFiltersState.defaults;
  if (filters.ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
      filters.mediaTypeFilter.isActive ||
      filters.tagFilter.isActive ||
      filters.authorFilter.isActive ||
      filters.languageFilter.isNotEmpty ||
      filters.parodyFilter.isNotEmpty ||
      filters.characterFilter.isNotEmpty ||
      filters.expandBySeries != LibraryExpandBySeries.defaultValue ||
      filters.needsMetadataOnly != LibraryNeedsMetadataOnly.defaultValue) {
    return true;
  }
  return filters.sortOption.field != kLibraryDefaultSortOption.field ||
      filters.sortOption.descending != kLibraryDefaultSortOption.descending;
});
