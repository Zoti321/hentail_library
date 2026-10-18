import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/core/errors/app_exception.dart';
import 'package:hentai_library/shared/core/logging/app_log.dart';
import 'package:hentai_library/shared/domain/library/metadata_refresh_port.dart';
import 'package:hentai_library/shared/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/features/library_admin/di/metadata_refresh.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_refresh_controller.freezed.dart';
part 'metadata_refresh_controller.g.dart';

enum MetadataRefreshTargetKind { comic, series, library }

@freezed
abstract class MetadataRefreshState with _$MetadataRefreshState {
  const factory MetadataRefreshState({
    @Default(false) bool running,
    String? targetLabel,
    MetadataRefreshTargetKind? targetKind,
    String? targetId,
    MetadataRefreshBatchResult? batchResult,
    String? error,
  }) = _MetadataRefreshState;

  const MetadataRefreshState._();
}

@Riverpod(keepAlive: true)
class MetadataRefreshController extends _$MetadataRefreshController {
  @override
  MetadataRefreshState build() => const MetadataRefreshState();

  MetadataRefreshPort get _port => ref.read(metadataRefreshPortProvider);

  void _notifyCatalogRevisionIfNeeded() {
    ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
  }

  Future<void> refreshComic({
    required String comicId,
    required String title,
  }) async {
    if (state.running) {
      throw AppException('元数据刷新进行中，请稍后再试');
    }
    _ensureScanIdle();

    state = MetadataRefreshState(
      running: true,
      targetLabel: title,
      targetKind: MetadataRefreshTargetKind.comic,
      targetId: comicId,
    );
    try {
      await _port.refreshComic(comicId);
      _notifyCatalogRevisionIfNeeded();
      state = const MetadataRefreshState();
    } catch (e, st) {
      logError(AppLog.ui('metadataRefresh'), '刷新漫画元数据失败', e, st);
      state = MetadataRefreshState(
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<MetadataRefreshBatchResult> refreshSeries({
    required String seriesId,
    required String name,
  }) async {
    if (state.running) {
      throw AppException('元数据刷新进行中，请稍后再试');
    }
    _ensureScanIdle();

    state = MetadataRefreshState(
      running: true,
      targetLabel: name,
      targetKind: MetadataRefreshTargetKind.series,
      targetId: seriesId,
    );
    try {
      final MetadataRefreshBatchResult batch = await _port.refreshSeries(
        seriesId,
      );
      _notifyCatalogRevisionIfNeeded();
      state = MetadataRefreshState(batchResult: batch);
      return batch;
    } catch (e, st) {
      logError(AppLog.ui('metadataRefresh'), '刷新系列元数据失败', e, st);
      state = MetadataRefreshState(
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<MetadataRefreshBatchResult> refreshLibrary({
    required String libraryId,
    required String name,
  }) async {
    if (state.running) {
      throw AppException('元数据刷新进行中，请稍后再试');
    }
    _ensureScanIdle();

    state = MetadataRefreshState(
      running: true,
      targetLabel: name,
      targetKind: MetadataRefreshTargetKind.library,
      targetId: libraryId,
    );
    try {
      final MetadataRefreshBatchResult result = await _port.refreshLibrary(
        libraryId,
      );
      if (!result.skipped) {
        _notifyCatalogRevisionIfNeeded();
      }
      state = MetadataRefreshState(batchResult: result);
      return result;
    } catch (e, st) {
      logError(AppLog.ui('metadataRefresh'), '刷新库元数据失败', e, st);
      state = MetadataRefreshState(
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  void cancel() {
    if (!state.running) {
      return;
    }
    _port.cancelActive();
  }

  bool isRefreshingLibrary(String libraryId) {
    return state.running &&
        state.targetKind == MetadataRefreshTargetKind.library &&
        state.targetId == libraryId;
  }

  bool isRefreshingSeries(String seriesId) {
    return state.running &&
        state.targetKind == MetadataRefreshTargetKind.series &&
        state.targetId == seriesId;
  }

  /// UI-friendly precheck only; authoritative mutual exclusion is Rust
  /// `library_write`.
  void _ensureScanIdle() {
    if (ref.read(scanLibraryControllerProvider).running) {
      throw AppException('库同步进行中，请稍后再试');
    }
  }
}
