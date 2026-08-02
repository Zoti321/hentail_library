import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/ui/features/shell/di/metadata_refresh.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_refresh_controller.freezed.dart';
part 'metadata_refresh_controller.g.dart';

@freezed
abstract class MetadataRefreshState with _$MetadataRefreshState {
  const factory MetadataRefreshState({
    @Default(false) bool running,
    String? targetLabel,
    RefreshSeriesProgress? seriesProgress,
    RefreshSeriesResult? seriesResult,
    String? error,
  }) = _MetadataRefreshState;

  const MetadataRefreshState._();
}

@Riverpod(keepAlive: true)
class MetadataRefreshController extends _$MetadataRefreshController {
  @override
  MetadataRefreshState build() => const MetadataRefreshState();

  Future<void> refreshComic({
    required String comicId,
    required String title,
  }) async {
    if (state.running) {
      throw AppException('元数据刷新进行中，请稍后再试');
    }
    _ensureScanIdle();

    state = MetadataRefreshState(running: true, targetLabel: title);
    try {
      await ref.read(metadataRefreshCoordinatorProvider).refreshComic(comicId);
      state = const MetadataRefreshState();
    } catch (e, st) {
      logError(AppLog.ui('metadataRefresh'), '刷新漫画元数据失败', e, st);
      state = MetadataRefreshState(
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<RefreshSeriesResult> refreshSeries({
    required String seriesId,
    required String name,
  }) async {
    if (state.running) {
      throw AppException('元数据刷新进行中，请稍后再试');
    }
    _ensureScanIdle();

    state = MetadataRefreshState(running: true, targetLabel: name);
    try {
      final RefreshSeriesResult result = await ref
          .read(metadataRefreshCoordinatorProvider)
          .refreshSeries(
            seriesId,
            onProgress: (RefreshSeriesProgress progress) {
              state = state.copyWith(seriesProgress: progress);
            },
          );
      state = MetadataRefreshState(seriesResult: result);
      return result;
    } catch (e, st) {
      logError(AppLog.ui('metadataRefresh'), '刷新系列元数据失败', e, st);
      state = MetadataRefreshState(
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  void _ensureScanIdle() {
    if (ref.read(scanLibraryControllerProvider).running) {
      throw AppException('库同步进行中，请稍后再试');
    }
  }
}
