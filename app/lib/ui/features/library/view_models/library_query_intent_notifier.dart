import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/ui/features/shell/view_models/debounced_action_runner.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
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
    if (state.sortOption.field == field) {
      setSortDescending(!state.sortOption.descending);
      return;
    }
    state = state.copyWith(
      sortOption: state.sortOption.copyWith(field: field, descending: false),
    );
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
      displayTarget: LibraryDisplayTarget.comics,
    );
  }

  void setMergeSearchQuery(String value) {
    _mergeSearchDebouncer.run(() {
      state = state.copyWith(mergeSearchQuery: value);
    });
  }

}
