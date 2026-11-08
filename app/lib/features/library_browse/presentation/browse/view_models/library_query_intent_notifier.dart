import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent.dart';
import 'package:hentai_library/core/util/debouncer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_query_intent_notifier.g.dart';

/// Intent 控制层：仅处理页面交互命令，负责更新查询意图状态。
/// 不直接读取漫画/系列数据，也不承担展示列表的派生逻辑。
@Riverpod(keepAlive: true)
class LibraryQueryIntentNotifier extends _$LibraryQueryIntentNotifier {
  static const _filterDebounceDuration = Duration(milliseconds: 300);
  late final Debouncer _filterQueryDebouncer = Debouncer(
    duration: _filterDebounceDuration,
  );

  @override
  LibraryQueryIntent build() {
    ref.onDispose(() {
      _filterQueryDebouncer.dispose();
    });
    ref.listen<LibraryDisplayTarget>(
      settingsProvider.select(
        (async) =>
            async.asData?.value.defaultLibraryDisplayTarget ??
            LibraryDisplayTarget.comics,
      ),
      (LibraryDisplayTarget? previous, LibraryDisplayTarget next) {
        if (previous == next) {
          return;
        }
        state = state.copyWith(displayTarget: next);
      },
    );
    return LibraryQueryIntent(displayTarget: _defaultLibraryDisplayTarget());
  }

  LibraryDisplayTarget _defaultLibraryDisplayTarget() {
    return ref
            .read(settingsProvider)
            .asData
            ?.value
            .defaultLibraryDisplayTarget ??
        LibraryDisplayTarget.comics;
  }

  void setFilterQuery(String? query) {
    _filterQueryDebouncer.run(() {
      state = state.copyWith(keyword: query ?? '');
    });
  }

  void setDisplayTarget(LibraryDisplayTarget target) {
    state = state.copyWith(displayTarget: target);
  }

  void clearKeyword() {
    state = state.copyWith(keyword: '');
  }

  void resetFilter() {
    state = state.copyWith(
      keyword: '',
      displayTarget: _defaultLibraryDisplayTarget(),
    );
  }
}
