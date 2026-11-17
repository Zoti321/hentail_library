import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/application/logging/app_log.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/features/library_admin/application/sync_library_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_sync_providers.dart';
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
    /// null when idle, or when [syncAll] is scanning every library.
    String? targetLibraryId,
    String? error,
    SyncLibraryProgress? progress,
  }) = _ScanLibraryState;

  const ScanLibraryState._();
}

@Riverpod(keepAlive: true)
class ScanLibraryController extends _$ScanLibraryController {
  _ScanLibraryRun? _activeRun;

  @override
  ScanLibraryState build() => const ScanLibraryState();

  /// Waits until any in-flight Library sync finishes (or was never running).
  Future<void> waitUntilIdle() async {
    while (ref.mounted && state.running) {
      final _ScanLibraryRun? run = _activeRun;
      if (run == null) {
        return;
      }
      await run.completion.future;
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
    if (state.running) {
      return _activeRun?.completion.future ?? Future<void>.value();
    }

    final SyncLibraryUseCase sync = ref.read(syncLibraryUseCaseProvider);
    final _ScanLibraryRun run = _ScanLibraryRun();
    _activeRun = run;
    state = state.copyWith(
      running: true,
      cancelled: false,
      silent: silent,
      fromStartup: fromStartup,
      scanMode: mode,
      // syncAll leaves target null so observers treat it as library-wide.
      targetLibraryId: syncAll ? null : targetLibraryId,
      error: null,
      progress: null,
    );

    run.completion.complete(() async {
      try {
        if (!_isCurrentRun(run)) {
          return;
        }
        await sync.run(
          mode: mode,
          syncAll: syncAll,
          targetLibraryId: targetLibraryId,
          isCancelled: () => !_isCurrentRun(run),
          onProgress: (SyncLibraryProgress progress) {
            if (_isCurrentRun(run)) {
              state = state.copyWith(progress: progress);
            }
          },
          promptStorageAccess: promptStorageAccess,
        );
        if (_isCurrentRun(run)) {
          state = state.copyWith(running: false, targetLibraryId: null);
        }
      } on Object catch (e, st) {
        logError(AppLog.ui('scan'), '漫画库同步失败', e, st);
        if (_isCurrentRun(run)) {
          final String message = appErrorMessage(e);
          state = state.copyWith(
            running: false,
            targetLibraryId: null,
            error: message,
          );
        }
      } finally {
        if (identical(_activeRun, run)) {
          _activeRun = null;
        }
      }
    }());

    return run.completion.future;
  }

  bool _isCurrentRun(_ScanLibraryRun run) =>
      ref.mounted && identical(_activeRun, run) && !run.cancelled;

  void cancel() {
    if (!state.running) return;
    final _ScanLibraryRun? run = _activeRun;
    if (run == null) return;
    run.cancelled = true;
    try {
      ref.read(syncLibraryUseCaseProvider).cancelActive();
    } finally {
      if (ref.mounted && identical(_activeRun, run)) {
        state = state.copyWith(
          running: false,
          cancelled: true,
          targetLibraryId: null,
        );
      }
    }
  }

  void setRunInBackground(bool value) {
    state = state.copyWith(runInBackground: value);
  }
}

class _ScanLibraryRun {
  final Completer<void> completion = Completer<void>();
  bool cancelled = false;
}
