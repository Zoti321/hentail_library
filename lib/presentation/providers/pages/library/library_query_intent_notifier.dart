import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';
import 'package:hentai_library/presentation/providers/common/debounced_action_runner.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_query_intent_notifier.g.dart';

/// Intent 控制层：仅处理页面交互命令，负责更新查询意图状态。
/// 不直接读取漫画/系列数据，也不承担展示列表的派生逻辑。
@Riverpod(keepAlive: true)
class LibraryQueryIntentNotifier extends _$LibraryQueryIntentNotifier {
  static const _filterDebounceDuration = Duration(milliseconds: 300);
  static const _mergeSearchDebounceDuration = Duration(milliseconds: 500);
  late final DebouncedActionRunner _filterQueryDebouncer =
      DebouncedActionRunner(duration: _filterDebounceDuration);
  late final DebouncedActionRunner _mergeSearchDebouncer =
      DebouncedActionRunner(duration: _mergeSearchDebounceDuration);

  @override
  LibraryQueryIntent build() {
    ref.onDispose(() {
      _filterQueryDebouncer.dispose();
      _mergeSearchDebouncer.dispose();
    });
    return LibraryQueryIntent();
  }

  void setFilterQuery(String? query) {
    _filterQueryDebouncer.run(() {
      state = state.copyWith(keyword: query ?? '');
    });
  }

  void setSortDescending(bool descending) {
    state = state.copyWith(
      sortOption: state.sortOption.copyWith(descending: descending),
    );
  }

  void setSortField(LibraryComicSortField field) {
    state = state.copyWith(sortOption: state.sortOption.copyWith(field: field));
  }

  void resetSortOption() {
    state = state.copyWith(sortOption: LibraryComicSortOption());
  }

  void setDisplayTarget(LibraryDisplayTarget target) {
    state = state.copyWith(displayTarget: target);
  }

  void resetFilter() {
    state = state.copyWith(
      keyword: '',
      displayTarget: LibraryDisplayTarget.all,
    );
  }

  void setMergeSearchQuery(String value) {
    _mergeSearchDebouncer.run(() {
      state = state.copyWith(mergeSearchQuery: value);
    });
  }

  void setIsGridView(bool isGridView) {
    state = state.copyWith(isGridView: isGridView);
  }
}
