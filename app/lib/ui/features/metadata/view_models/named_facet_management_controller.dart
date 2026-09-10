import 'dart:async';

import 'package:hentai_library/core/utils/name_pinyin_assisted_filter.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
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
    this.error,
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
  final Object? error;

  bool get hasSearchQuery => query.trim().isNotEmpty;
  bool get isEmpty => !isLoading && items.isEmpty;

  NamedFacetManagementState copyWith({
    String? query,
    List<String>? items,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _sentinel,
  }) {
    return NamedFacetManagementState(
      query: query ?? this.query,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _sentinel) ? this.error : error,
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
        final List<String> filtered = all
            .where(
              (String item) =>
                  nameMatchesPinyinAssistedFilter(item, state.query),
            )
            .toList();
        state = state.copyWith(
          items: filtered,
          totalCount: filtered.length,
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          error: null,
        );
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

  Future<int> countAttachments(String name) {
    return ref
        .read(namedFacetManagementRepoProvider)
        .countAttachments(kind, name);
  }
}
