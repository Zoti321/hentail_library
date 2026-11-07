import 'dart:async';

import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/util/name_pinyin_assisted_filter.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'named_facet_management_controller.g.dart';

const int kNamedFacetManagementPageSize = 80;

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
class NamedFacetManagementController extends _$NamedFacetManagementController {
  int _page = 1;

  @override
  NamedFacetManagementState build(ManagedNamedFacetKind kind) {
    Future<void>.microtask(refresh);
    return NamedFacetManagementState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      if (state.hasSearchQuery) {
        final List<String> all = await ref
            .read(namedFacetManagementRepoProvider)
            .listAll(kind);
        final NamePinyinIndex index = await buildNamePinyinIndex(all);
        final List<String> filtered = all
            .where((String item) => index.matches(item, state.query))
            .toList();
        state = state.copyWith(
          items: filtered,
          totalCount: filtered.length,
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          error: null,
        );
        unawaited(_prefetchAttachmentCounts(filtered));
        return;
      }

      _page = 1;
      final result = await ref
          .read(namedFacetManagementRepoProvider)
          .fetchPage(
            kind,
            pageRequest(page: _page, pageSize: kNamedFacetManagementPageSize),
          );
      state = state.copyWith(
        items: result.items,
        totalCount: result.totalCount,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.items.length < result.totalCount,
        error: null,
      );
      unawaited(_prefetchAttachmentCounts(result.items));
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: error,
      );
    }
  }

  Future<void> setQuery(String value) async {
    final String next = value.trim();
    if (next == state.query) {
      return;
    }
    state = state.copyWith(query: next);
    await refresh();
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
      final List<String> merged = <String>[...state.items, ...result.items];
      state = state.copyWith(
        items: merged,
        totalCount: result.totalCount,
        isLoadingMore: false,
        hasMore: merged.length < result.totalCount,
        error: null,
      );
      unawaited(_prefetchAttachmentCounts(result.items));
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> add(String name) async {
    await ref.read(namedFacetManagementRepoProvider).add(kind, name);
    await refresh();
  }

  Future<void> rename(String oldName, String newName) async {
    final String trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) {
      return;
    }
    await ref
        .read(namedFacetManagementRepoProvider)
        .rename(kind, oldName, trimmed);
    await refresh();
  }

  Future<void> delete(String name) async {
    await ref.read(namedFacetManagementRepoProvider).deleteByNames(
      kind,
      <String>[name],
    );
    await refresh();
  }

  /// 标签字典变了（清空或导入）之后，管理页和 [allTagsProvider] 读同一份名字。
  Future<void> refreshAfterTagDictionaryChange() async {
    ref.invalidate(allTagsProvider);
    if (kind == ManagedNamedFacetKind.tag) {
      await refresh();
    }
  }

  void enterMerge(String target) {
    if (kind == ManagedNamedFacetKind.author) {
      return;
    }
    state = state.copyWith(
      mergeTarget: target,
      mergeSources: const <String>{},
    );
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
    final repo = ref.read(namedFacetManagementRepoProvider);
    for (final String sourceName in sourceNames) {
      await repo.merge(kind, sourceName, targetName);
    }
    exitMerge();
    await refresh();
  }

  Future<int> countAttachments(String name) {
    return ref
        .read(namedFacetManagementRepoProvider)
        .countAttachments(kind, name);
  }

  Future<void> _prefetchAttachmentCounts(List<String> names) async {
    if (kind == ManagedNamedFacetKind.author || names.isEmpty) {
      return;
    }
    final Map<String, int> next = Map<String, int>.of(state.attachmentCounts);
    await Future.wait(
      names.map((String name) async {
        try {
          next[name] = await ref
              .read(namedFacetManagementRepoProvider)
              .countAttachments(kind, name);
        } catch (_) {}
      }),
    );
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(attachmentCounts: next);
  }
}
