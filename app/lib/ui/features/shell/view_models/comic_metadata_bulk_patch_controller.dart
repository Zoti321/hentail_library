import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/ui/features/shell/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_metadata_bulk_patch_controller.g.dart';

class ComicMetadataBulkPatchState {
  const ComicMetadataBulkPatchState({
    this.running = false,
    this.comicCount = 0,
    this.batchResult,
    this.error,
  });

  final bool running;
  final int comicCount;
  final ComicMetadataBulkPatchResult? batchResult;
  final String? error;

  ComicMetadataBulkPatchState copyWith({
    bool? running,
    int? comicCount,
    ComicMetadataBulkPatchResult? batchResult,
    String? error,
    bool clearBatchResult = false,
    bool clearError = false,
  }) {
    return ComicMetadataBulkPatchState(
      running: running ?? this.running,
      comicCount: comicCount ?? this.comicCount,
      batchResult: clearBatchResult ? null : batchResult ?? this.batchResult,
      error: clearError ? null : error ?? this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class ComicMetadataBulkPatchController
    extends _$ComicMetadataBulkPatchController {
  @override
  ComicMetadataBulkPatchState build() => const ComicMetadataBulkPatchState();

  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) async {
    if (state.running) {
      throw AppException('批量编辑进行中，请稍后再试');
    }
    _ensureWriteIdle();

    state = ComicMetadataBulkPatchState(
      running: true,
      comicCount: comicIds.length,
    );
    try {
      final ComicMetadataBulkPatchResult result = await ref
          .read(comicMetadataBulkPatchCoordinatorProvider)
          .apply(comicIds: comicIds, patch: patch);
      if (result.succeeded > 0) {
        ref
            .read(metadataAutoBackupCoordinatorProvider.notifier)
            .notifyMetadataSaved();
      }
      state = ComicMetadataBulkPatchState(batchResult: result);
      return result;
    } catch (e, st) {
      logError(AppLog.ui('bulkPatch'), '批量编辑元数据失败', e, st);
      state = ComicMetadataBulkPatchState(
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  void cancel() {
    if (!state.running) {
      return;
    }
    ref.read(comicMetadataBulkPatchCoordinatorProvider).cancelActive();
  }

  void clearResult() {
    state = const ComicMetadataBulkPatchState();
  }

  void _ensureWriteIdle() {
    if (ref.read(scanLibraryControllerProvider).running) {
      throw AppException('库同步进行中，请稍后再试');
    }
    if (ref.read(metadataRefreshControllerProvider).running) {
      throw AppException('元数据刷新进行中，请稍后再试');
    }
  }
}
