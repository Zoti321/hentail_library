import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/core/io/local_library_root_access.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/shared/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/shared/domain/library/sync_library_port.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/di/library_sync.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
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
    @Default(false) bool fromStartup,
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

  /// Waits until any in-flight Library sync finishes (or was never running).
  Future<void> waitUntilIdle() async {
    while (state.running) {
      final Future<void>? inFlight = _future;
      if (inFlight == null) {
        return;
      }
      await inFlight;
    }
  }

  /// 幂等启动：若已在运行则直接返回同一个 Future。
  Future<void> start({
    ScanMode mode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    bool silent = false,
    bool fromStartup = false,
    bool promptStorageAccess = true,
  }) {
    if (state.running) return _future ?? Future<void>.value();

    _cancelled = false;
    state = state.copyWith(
      running: true,
      cancelled: false,
      silent: silent,
      fromStartup: fromStartup,
      scanMode: mode,
      error: null,
      progress: null,
    );

    final SyncLibraryPort syncAdapter = ref.read(syncLibraryPortProvider);
    _future =
        () async {
              if (promptStorageAccess) {
                await ensureLocalFilesystemAccess();
              }
              if (_cancelled) {
                return;
              }
              await syncAdapter.call(
                scanMode: mode,
                syncAll: syncAll,
                targetLibraryId: targetLibraryId,
                isCancelled: () => _cancelled,
                onProgress: (SyncLibraryProgress progress) {
                  state = state.copyWith(progress: progress);
                },
              );
              if (!_cancelled) {
                ref
                    .read(libraryRevisionProvider.notifier)
                    .notifyExternalChange();
              }
            }()
            .then((_) {
              state = state.copyWith(running: false);
            })
            .catchError((Object e, StackTrace st) {
              logError(AppLog.ui('scan'), '漫画库同步失败', e, st);
              final String message = caughtErrorMessage(
                e,
                fallbackMessage: '漫画库同步失败',
              );
              state = state.copyWith(running: false, error: message);
            });

    return _future!;
  }

  void cancel() {
    if (!state.running) return;
    _cancelled = true;
    ref.read(syncLibraryPortProvider).cancelActive();
    state = state.copyWith(running: false, cancelled: true);
  }

  void setRunInBackground(bool value) {
    state = state.copyWith(runInBackground: value);
  }
}
