import 'dart:async';

import 'package:hentai_library/features/named_metadata/di/named_facet_management.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/util/name_pinyin_assisted_filter.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/named_metadata/public/di/named_metadata_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'named_facet_management_view_model.g.dart';

const int kNamedFacetManagementPageSize = 80;
const Duration kNamedFacetSearchDebounce = Duration(milliseconds: 280);

class NamedFacetManagementState {
  const NamedFacetManagementState({
    required this.query,
    required this.items,
    required this.totalCount,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.attachmentCounts = const <String, int>{},
    this.error,
    this.mergeTarget,
    this.mergeSources = const <String>{},
  });

  factory NamedFacetManagementState.initial() =>
      const NamedFacetManagementState(
        query: '',
        items: <String>[],
        totalCount: 0,
        isLoading: true,
        isLoadingMore: false,
        hasMore: false,
      );

  final String query;
  final List<String> items;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Map<String, int> attachmentCounts;
  final Object? error;

  /// 合并模式目标名；null 表示未进入合并。
  final String? mergeTarget;
  final Set<String> mergeSources;

  bool get hasSearchQuery => query.trim().isNotEmpty;
  bool get isEmpty => !isLoading && items.isEmpty;
  bool get isMergeMode => mergeTarget != null;
  int get mergeSelectionCount =>
      mergeTarget == null ? 0 : 1 + mergeSources.length;

  NamedFacetManagementState copyWith({
    String? query,
    List<String>? items,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Map<String, int>? attachmentCounts,
    Object? error = _sentinel,
    String? mergeTarget,
    bool clearMergeTarget = false,
    Set<String>? mergeSources,
  }) {
    return NamedFacetManagementState(
      query: query ?? this.query,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      attachmentCounts: attachmentCounts ?? this.attachmentCounts,
      error: identical(error, _sentinel) ? this.error : error,
      mergeTarget: clearMergeTarget ? null : (mergeTarget ?? this.mergeTarget),
      mergeSources: mergeSources ?? this.mergeSources,
    );
  }
}

const Object _sentinel = Object();

@Riverpod(keepAlive: true)
class NamedFacetManagementViewModel extends _$NamedFacetManagementViewModel {
  int _page = 1;
  List<String>? _searchAllNames;
  NamePinyinIndex? _searchPinyinIndex;
  Timer? _searchDebounce;
  int _searchGeneration = 0;

  @override
  NamedFacetManagementState build(ManagedNamedFacetKind kind) {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });
    Future<void>.microtask(refresh);
    return NamedFacetManagementState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      if (state.hasSearchQuery) {
        await _refreshSearch();
        return;
      }

      _invalidateSearchCache();
      _page = 1;
      final result = await ref
          .read(namedFacetManagementRepoProvider)
          .fetchPage(
            kind,
            pageRequest(page: _page, pageSize: kNamedFacetManagementPageSize),
          );
      state = state.copyWith(
        items: <String>[
          for (final NamedFacetFormCandidate entry in result.items) entry.name,
        ],
        totalCount: result.totalCount,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.items.length < result.totalCount,
        attachmentCounts: _countsFromEntries(result.items),
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: error,
      );
    }
  }

  /// Immediate query apply (tests / programmatic). UI should prefer [setQueryDebounced].
  Future<void> setQuery(String value) async {
    _searchDebounce?.cancel();
    final String next = value.trim();
    if (next == state.query) {
      return;
    }
    state = state.copyWith(query: next);
    await refresh();
  }

  void setQueryDebounced(String value) {
    final String next = value.trim();
    if (next == state.query) {
      return;
    }
    _searchDebounce?.cancel();
    final int generation = ++_searchGeneration;
    _searchDebounce = Timer(kNamedFacetSearchDebounce, () {
      if (!ref.mounted || generation != _searchGeneration) {
        return;
      }
      unawaited(setQuery(next));
    });
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.hasSearchQuery ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final int nextPage = _page + 1;
      final result = await ref
          .read(namedFacetManagementRepoProvider)
          .fetchPage(
            kind,
            pageRequest(
              page: nextPage,
              pageSize: kNamedFacetManagementPageSize,
            ),
          );
      _page = result.page;
      final List<String> pageNames = <String>[
        for (final NamedFacetFormCandidate entry in result.items) entry.name,
      ];
      final List<String> merged = <String>[...state.items, ...pageNames];
      final Map<String, int> counts = Map<String, int>.of(
        state.attachmentCounts,
      )..addAll(_countsFromEntries(result.items));
      state = state.copyWith(
        items: merged,
        totalCount: result.totalCount,
        isLoadingMore: false,
        hasMore: merged.length < result.totalCount,
        attachmentCounts: counts,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> add(String name) async {
    await ref.read(namedFacetManagementServiceProvider).add(kind, name);
    await refresh();
  }

  Future<void> rename(String oldName, String newName) async {
    await ref
        .read(namedFacetManagementServiceProvider)
        .rename(kind, oldName, newName);
    await refresh();
  }

  Future<void> delete(String name) async {
    await ref.read(namedFacetManagementServiceProvider).delete(kind, name);
    await refresh();
  }

  /// 标签字典变了（清空或导入）之后，管理页和 [allTagsProvider] 读同一份名字。
  Future<void> refreshAfterTagDictionaryChange() async {
    ref.invalidate(allTagsProvider);
    if (kind == ManagedNamedFacetKind.tag) {
      _invalidateSearchCache();
      await refresh();
    }
  }

  void enterMerge(String target) {
    if (kind == ManagedNamedFacetKind.author) {
      return;
    }
    state = state.copyWith(mergeTarget: target, mergeSources: const <String>{});
  }

  void toggleMergeSource(String source) {
    final String? target = state.mergeTarget;
    if (target == null || source == target) {
      return;
    }
    final Set<String> next = <String>{...state.mergeSources};
    if (!next.add(source)) {
      next.remove(source);
    }
    state = state.copyWith(mergeSources: next);
  }

  void exitMerge() {
    if (!state.isMergeMode && state.mergeSources.isEmpty) {
      return;
    }
    state = state.copyWith(
      clearMergeTarget: true,
      mergeSources: const <String>{},
    );
  }

  Future<void> merge({
    required String targetName,
    required List<String> sourceNames,
  }) async {
    await ref
        .read(namedFacetManagementServiceProvider)
        .merge(kind: kind, targetName: targetName, sourceNames: sourceNames);
    exitMerge();
    await refresh();
  }

  Future<int> countAttachments(String name) {
    return ref
        .read(namedFacetManagementServiceProvider)
        .countAttachments(kind, name);
  }

  Future<void> _refreshSearch() async {
    final List<String> all = await _ensureSearchSnapshot();
    final NamePinyinIndex index = _searchPinyinIndex!;
    final List<String> filtered = all
        .where((String item) => index.matches(item, state.query))
        .toList();
    Map<String, int> counts = const <String, int>{};
    if (kind != ManagedNamedFacetKind.author && filtered.isNotEmpty) {
      counts = await ref
          .read(namedFacetManagementServiceProvider)
          .countAttachmentsBatch(kind, filtered);
    }
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      items: filtered,
      totalCount: filtered.length,
      isLoading: false,
      isLoadingMore: false,
      hasMore: false,
      attachmentCounts: counts,
      error: null,
    );
  }

  Future<List<String>> _ensureSearchSnapshot() async {
    final List<String>? cached = _searchAllNames;
    if (cached != null && _searchPinyinIndex != null) {
      return cached;
    }
    final List<String> all = await ref
        .read(namedFacetManagementRepoProvider)
        .listAll(kind);
    _searchAllNames = all;
    _searchPinyinIndex = await buildNamePinyinIndex(all);
    return all;
  }

  void _invalidateSearchCache() {
    _searchAllNames = null;
    _searchPinyinIndex = null;
  }

  Map<String, int> _countsFromEntries(List<NamedFacetFormCandidate> entries) {
    if (kind == ManagedNamedFacetKind.author) {
      return const <String, int>{};
    }
    return <String, int>{
      for (final NamedFacetFormCandidate entry in entries)
        entry.name: entry.attachmentCount,
    };
  }
}
