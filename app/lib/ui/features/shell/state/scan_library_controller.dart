import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/domain/library/library_sync_coordinator.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/ui/features/shell/di/library_sync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_library_controller.freezed.dart';
part 'scan_library_controller.g.dart';

@freezed
abstract class ScanLibraryState with _$ScanLibraryState {
  const factory ScanLibraryState({
    @Default(false) bool running,
    @Default(false) bool cancelled,
    @Default(false) bool runInBackground,
    @Default(false) bool silent,
    @Default(ScanMode.incremental) ScanMode scanMode,
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
  Future<void> start({
    ScanMode mode = ScanMode.incremental,
    bool silent = false,
  }) {
    if (state.running) return _future ?? Future<void>.value();

    _cancelled = false;
    state = state.copyWith(
      running: true,
      cancelled: false,
      silent: silent,
      scanMode: mode,
      error: null,
      progress: null,
    );

    final LibrarySyncCoordinator coordinator = ref.read(
      librarySyncCoordinatorProvider,
    );
    _future = coordinator
        .runSync(
          scanMode: mode,
          isCancelled: () => _cancelled,
          onProgress: (SyncLibraryProgress progress) {
            state = state.copyWith(progress: progress);
          },
        )
        .then((_) {
          state = state.copyWith(running: false);
        })
        .catchError((Object e, StackTrace st) {
          logError(AppLog.ui('scan'), '漫画库同步失败', e, st);
          final String message = switch (e) {
            AppException(:final message) => message,
            HentaiErrorDto error => frbErrorMessage(
              error,
              fallbackMessage: '漫画库同步失败',
            ),
            _ => e.toString(),
          };
          state = state.copyWith(running: false, error: message);
        });

    return _future!;
  }

  void cancel() {
    if (!state.running) return;
    _cancelled = true;
    ref.read(librarySyncCoordinatorProvider).cancelActive();
    state = state.copyWith(running: false, cancelled: true);
  }

  void setRunInBackground(bool value) {
    state = state.copyWith(runInBackground: value);
  }
}
