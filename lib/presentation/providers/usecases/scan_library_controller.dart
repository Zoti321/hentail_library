import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/presentation/providers/usecases/sync_library.dart';
import 'package:hentai_library/presentation/providers/usecases/sync_library_progress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_library_controller.freezed.dart';
part 'scan_library_controller.g.dart';

@freezed
abstract class ScanLibraryState with _$ScanLibraryState {
  const factory ScanLibraryState({
    @Default(false) bool running,
    @Default(false) bool cancelled,
    @Default(false) bool runInBackground,
    String? error,
    SyncLibraryProgress? progress,
  }) = _ScanLibraryState;

  const ScanLibraryState._();
}

@Riverpod(keepAlive: true)
class ScanLibraryController extends _$ScanLibraryController {
  bool _cancelled = false;
  Future<void>? _future;

  @override
  ScanLibraryState build() => const ScanLibraryState();

  /// 幂等启动：若已在运行则直接返回同一个 Future。
  Future<void> start() {
    if (state.running) return _future ?? Future<void>.value();

    _cancelled = false;
    state = state.copyWith(
      running: true,
      cancelled: false,
      error: null,
      progress: null,
    );

    final useCase = ref.read(syncComicsUseCaseProvider);
    _future = useCase
        .call(
          isCancelled: () => _cancelled,
          onProgress: (p) {
            state = state.copyWith(progress: p);
          },
        )
        .then((_) {
          state = state.copyWith(running: false);
        })
        .catchError((Object e, StackTrace st) {
          final message = e is AppException ? e.message : e.toString();
          state = state.copyWith(running: false, error: message);
          Error.throwWithStackTrace(e, st);
        });

    return _future!;
  }

  void cancel() {
    if (!state.running) return;
    _cancelled = true;
    state = state.copyWith(running: false, cancelled: true);
  }

  void setRunInBackground(bool value) {
    state = state.copyWith(runInBackground: value);
  }
}

