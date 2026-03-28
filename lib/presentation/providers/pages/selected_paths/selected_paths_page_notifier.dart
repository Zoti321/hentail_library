import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_paths_page_notifier.freezed.dart';
part 'selected_paths_page_notifier.g.dart';

@freezed
abstract class SelectedPathsPageState with _$SelectedPathsPageState {
  const factory SelectedPathsPageState({
    @Default(<String>[]) List<String> paths,
    @Default(false) bool isSelectionMode,
    @Default(<String>{}) Set<String> selectedPaths,
  }) = _SelectedPathsPageState;
}

@riverpod
class SelectedPathsPageNotifier extends _$SelectedPathsPageNotifier {
  PathRepository get _pathRepo => ref.read(pathRepoProvider);

  StreamSubscription<List<String>>? _pathsSub;

  @override
  Future<SelectedPathsPageState> build() async {
    ref.onDispose(() => _pathsSub?.cancel());
    _pathsSub = _pathRepo.watch().listen(
      _applyPathsFromStream,
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
    final initialPaths = await _pathRepo.getAll();
    return SelectedPathsPageState(paths: initialPaths);
  }

  Future<void> refreshPaths() async {
    final previous = _currentOrDefault();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final paths = await _pathRepo.getAll();
      return _syncPathsAndSelection(previous, paths);
    });
  }

  void setSelectionMode(bool enabled) {
    _updateDataState((current) {
      if (!enabled) {
        return current.copyWith(
          isSelectionMode: false,
          selectedPaths: const <String>{},
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

  void togglePathSelection(String path) {
    _updateDataState((current) {
      if (!current.isSelectionMode) {
        return current;
      }

      if (!current.paths.contains(path)) {
        return current;
      }

      final nextSelected = <String>{...current.selectedPaths};
      if (!nextSelected.add(path)) {
        nextSelected.remove(path);
      }

      return current.copyWith(selectedPaths: nextSelected);
    });
  }

  void clearSelection() {
    _updateDataState(
      (current) => current.copyWith(selectedPaths: const <String>{}),
    );
  }

  void _applyPathsFromStream(List<String> paths) {
    final current = _currentOrDefault();
    state = AsyncData(_syncPathsAndSelection(current, paths));
  }

  SelectedPathsPageState _currentOrDefault() {
    return state.asData?.value ?? const SelectedPathsPageState();
  }

  SelectedPathsPageState _syncPathsAndSelection(
    SelectedPathsPageState current,
    List<String> paths,
  ) {
    final validSelected = current.selectedPaths.where(paths.contains).toSet();
    return current.copyWith(paths: paths, selectedPaths: validSelected);
  }

  void _updateDataState(
    SelectedPathsPageState Function(SelectedPathsPageState) updater,
  ) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }
}
