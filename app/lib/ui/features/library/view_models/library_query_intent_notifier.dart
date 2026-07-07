import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/shell/view_models/debounced_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_query_intent_notifier.g.dart';

/// Intent 控制层：仅处理页面交互命令，负责更新查询意图状态。
/// 不直接读取漫画/系列数据，也不承担展示列表的派生逻辑。
@Riverpod(keepAlive: true)
class LibraryQueryIntentNotifier extends _$LibraryQueryIntentNotifier {
  static const _filterDebounceDuration = Duration(milliseconds: 300);
  late final DebouncedActionRunner _filterQueryDebouncer =
      DebouncedActionRunner(duration: _filterDebounceDuration);

  @override
  LibraryQueryIntent build() {
    ref.onDispose(() {
      _filterQueryDebouncer.dispose();
    });
    return LibraryQueryIntent();
  }

  void setFilterQuery(String? query) {
    _filterQueryDebouncer.run(() {
      state = state.copyWith(keyword: query ?? '');
    });
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
}
