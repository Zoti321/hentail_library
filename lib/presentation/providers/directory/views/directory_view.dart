import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/presentation/providers/directory/directory_query_providers.dart';
import 'package:hentai_library/presentation/providers/directory/directory_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directory_view.freezed.dart';
part 'directory_view.g.dart';

@freezed
abstract class DirectoryViewState with _$DirectoryViewState {
  const factory DirectoryViewState({
    @Default(<String>[]) List<String> dirs,
    @Default(false) bool isSelectionMode,
    @Default(<String>{}) Set<String> selectedDirs,
  }) = _DirectoryViewState;
}

@riverpod
class DirectoryViewNotifier extends _$DirectoryViewNotifier {
  PathRepository get _pathRepo => ref.read(pathRepoProvider);

  @override
  Future<DirectoryViewState> build() async {
    // 监听目录流，目录变化时自动刷新页面状态
    _listenDirsStream();

    // 首屏先读取一次，避免首次渲染为空
    final initialDirs = await _pathRepo.getAllPaths();
    return DirectoryViewState(dirs: initialDirs);
  }

  Future<void> refreshDirs() async {
    final previous = _currentOrDefault();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dirs = await _pathRepo.getAllPaths();
      return _syncDirsAndSelection(previous, dirs);
    });
  }

  void setSelectionMode(bool enabled) {
    _updateDataState((current) {
      if (!enabled) {
        // 退出选择模式时清空已选目录，避免脏状态
        return current.copyWith(
          isSelectionMode: false,
          selectedDirs: const <String>{},
        );
      }
      return current.copyWith(isSelectionMode: true);
    });
  }

  void toggleSelectionMode() {
    final current = state.asData?.value;
    if (current == null) return;
    setSelectionMode(!current.isSelectionMode);
  }

  void toggleDirSelection(String dir) {
    _updateDataState((current) {
      // 非选择模式时忽略点击
      if (!current.isSelectionMode) {
        return current;
      }

      // 仅允许选择当前目录列表中的路径，保证状态一致
      if (!current.dirs.contains(dir)) {
        return current;
      }

      final nextSelected = <String>{...current.selectedDirs};
      if (!nextSelected.add(dir)) {
        nextSelected.remove(dir);
      }

      return current.copyWith(selectedDirs: nextSelected);
    });
  }

  void clearSelection() {
    _updateDataState(
      (current) => current.copyWith(selectedDirs: const <String>{}),
    );
  }

  void _listenDirsStream() {
    ref.listen(pathsStreamProvider, (_, next) {
      next.when(
        // 目录流作为目录列表的单一来源
        data: _applyDirsFromStream,
        error: (error, stackTrace) {
          state = AsyncError(error, stackTrace);
        },
        loading: () {
          // 流进入加载态时保持当前 UI，避免闪烁
        },
      );
    });
  }

  void _applyDirsFromStream(List<String> dirs) {
    final current = _currentOrDefault();
    state = AsyncData(_syncDirsAndSelection(current, dirs));
  }

  DirectoryViewState _currentOrDefault() {
    return state.asData?.value ?? const DirectoryViewState();
  }

  DirectoryViewState _syncDirsAndSelection(
    DirectoryViewState current,
    List<String> dirs,
  ) {
    final validSelected = current.selectedDirs.where(dirs.contains).toSet();
    return current.copyWith(dirs: dirs, selectedDirs: validSelected);
  }

  void _updateDataState(
    DirectoryViewState Function(DirectoryViewState) updater,
  ) {
    // 仅在有数据态时更新，避免覆盖加载态和错误态
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }
}
