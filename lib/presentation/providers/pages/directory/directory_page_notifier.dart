import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directory_page_notifier.freezed.dart';
part 'directory_page_notifier.g.dart';

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

  StreamSubscription<List<String>>? _dirsSub;

  @override
  Future<DirectoryViewState> build() async {
    ref.onDispose(() => _dirsSub?.cancel());
    _dirsSub = _pathRepo.watch().listen(
      _applyDirsFromStream,
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
    final initialDirs = await _pathRepo.getAll();
    return DirectoryViewState(dirs: initialDirs);
  }

  Future<void> refreshDirs() async {
    final previous = _currentOrDefault();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dirs = await _pathRepo.getAll();
      return _syncDirsAndSelection(previous, dirs);
    });
  }

  void setSelectionMode(bool enabled) {
    _updateDataState((current) {
      if (!enabled) {
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
      if (!current.isSelectionMode) {
        return current;
      }

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
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }
}
