import 'dart:async';
import 'dart:io' show FileSystemEntity, FileSystemEntityType;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_paths_page_notifier.freezed.dart';
part 'selected_paths_page_notifier.g.dart';

@freezed
abstract class SelectedPathsPageState with _$SelectedPathsPageState {
  const factory SelectedPathsPageState({
    @Default(<String>[]) List<String> paths,
    @Default(<String, FileSystemEntityType>{})
    Map<String, FileSystemEntityType> pathTypes,
  }) = _SelectedPathsPageState;
}

@riverpod
class SelectedPathsPageNotifier extends _$SelectedPathsPageNotifier {
  PathRepository get _pathRepo => ref.read(pathRepoProvider);

  StreamSubscription<List<String>>? _pathsSub;
  int _pathTypeRefreshToken = 0;

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
    final Map<String, FileSystemEntityType> initialPathTypes =
        await _resolvePathTypes(
          paths: initialPaths,
          previousTypes: const <String, FileSystemEntityType>{},
        );
    return SelectedPathsPageState(
      paths: initialPaths,
      pathTypes: initialPathTypes,
    );
  }

  Future<void> refreshPaths() async {
    final previous = _currentOrDefault();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final paths = await _pathRepo.getAll();
      final Map<String, FileSystemEntityType> nextPathTypes =
          await _resolvePathTypes(
            paths: paths,
            previousTypes: previous.pathTypes,
          );
      return SelectedPathsPageState(paths: paths, pathTypes: nextPathTypes);
    });
  }

  void _applyPathsFromStream(List<String> paths) {
    final current = _currentOrDefault();
    state = AsyncData(_syncPaths(current, paths));
    unawaited(_refreshPathTypes(paths));
  }

  SelectedPathsPageState _currentOrDefault() {
    return state.asData?.value ?? const SelectedPathsPageState();
  }

  SelectedPathsPageState _syncPaths(
    SelectedPathsPageState current,
    List<String> paths,
  ) {
    final Map<String, FileSystemEntityType> nextPathTypes =
        <String, FileSystemEntityType>{};
    for (final String path in paths) {
      final FileSystemEntityType? cachedType = current.pathTypes[path];
      if (cachedType != null) {
        nextPathTypes[path] = cachedType;
      }
    }
    return current.copyWith(paths: paths, pathTypes: nextPathTypes);
  }

  void _updateDataState(
    SelectedPathsPageState Function(SelectedPathsPageState) updater,
  ) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  Future<void> _refreshPathTypes(List<String> paths) async {
    _pathTypeRefreshToken++;
    final int token = _pathTypeRefreshToken;
    final SelectedPathsPageState current = _currentOrDefault();
    final Map<String, FileSystemEntityType> nextPathTypes =
        await _resolvePathTypes(paths: paths, previousTypes: current.pathTypes);
    if (token != _pathTypeRefreshToken) {
      return;
    }
    _updateDataState(
      (SelectedPathsPageState stateData) =>
          stateData.copyWith(pathTypes: nextPathTypes),
    );
  }

  Future<Map<String, FileSystemEntityType>> _resolvePathTypes({
    required List<String> paths,
    required Map<String, FileSystemEntityType> previousTypes,
  }) async {
    final Map<String, FileSystemEntityType> next =
        <String, FileSystemEntityType>{};
    final List<Future<void>> tasks = <Future<void>>[];
    for (final String path in paths) {
      final FileSystemEntityType? cachedType = previousTypes[path];
      if (cachedType != null) {
        next[path] = cachedType;
        continue;
      }
      tasks.add(
        FileSystemEntity.type(path, followLinks: false).then((
          FileSystemEntityType t,
        ) {
          next[path] = t;
        }),
      );
    }
    await Future.wait(tasks);
    return next;
  }
}
