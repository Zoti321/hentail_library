import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/services/comic/cache/archive_cover_cache.dart';
import 'package:hentai_library/services/comic/read_resource_get/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/comic_read_resource_session_manager.dart';
import 'package:hentai_library/services/comic/read_resource_get/isolate_archive_cover_loader.dart';
import 'package:hentai_library/services/comic/read_resource_get/reader_image.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/models.dart' as entity;
import 'package:hentai_library/presentation/providers/aggregates/reading_aggregate_notifier.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_window_fullscreen.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/presentation/providers/pages/reader/series_reader_provider.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/widgets/reader_route_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_page_notifier.freezed.dart';
part 'reader_page_notifier.g.dart';

enum ReaderTapZone { left, center, right }

sealed class ReaderPageImageData {
  const ReaderPageImageData();
}

class ReaderDirPageImageData extends ReaderPageImageData {
  const ReaderDirPageImageData(this.file);
  final File file;
}

class ReaderArchivePageImageData extends ReaderPageImageData {
  const ReaderArchivePageImageData({
    required this.comicId,
    required this.pageIndex,
  });
  final String comicId;
  final int pageIndex;
}

@freezed
abstract class ReaderViewState with _$ReaderViewState {
  factory ReaderViewState({
    required Comic comic,
    @Default(false) bool isVertical,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
  }) = _ReaderViewState;

  ReaderViewState._();

  int get totalPages => totalPagesOverride ?? 0;
}

class ReaderPageViewModel {
  const ReaderPageViewModel({
    required this.viewState,
    required this.navContext,
    required this.preferredPageIndex,
  });
  final ReaderViewState viewState;
  final ReaderNavContextData navContext;
  final int? preferredPageIndex;
}

@riverpod
AsyncValue<ReaderPageViewModel> readerPageViewModel(
  Ref ref, {
  required String comicId,
  required bool isSeriesMode,
  String? seriesName,
}) {
  final AsyncValue<ReaderViewState> viewAsync = ref.watch(
    readerViewProvider(comicId),
  );
  final AsyncValue<ReaderSeriesContextData> seriesContextAsync = ref.watch(
    readerSeriesContextForReaderProvider(
      comicId: comicId,
      isSeriesMode: isSeriesMode,
      seriesName: seriesName,
    ),
  );
  if (viewAsync.hasError) {
    return AsyncError(viewAsync.error!, viewAsync.stackTrace!);
  }
  if (seriesContextAsync.hasError) {
    return AsyncError(
      seriesContextAsync.error!,
      seriesContextAsync.stackTrace!,
    );
  }
  final ReaderViewState? viewState = viewAsync.asData?.value;
  final ReaderSeriesContextData? seriesContext =
      seriesContextAsync.asData?.value;
  if (viewState == null || seriesContext == null) {
    return const AsyncLoading();
  }
  return AsyncData(
    ReaderPageViewModel(
      viewState: viewState,
      navContext: seriesContext.navContext,
      preferredPageIndex: seriesContext.preferredPageIndex,
    ),
  );
}

@riverpod
class ReaderViewNotifier extends _$ReaderViewNotifier {
  @override
  Future<ReaderViewState> build(String id) async {
    final comic = await ref.read(comicRepoProvider).findById(id);
    if (comic == null) {
      throw StateError('Comic not found: $id');
    }
    final progress = await ref.watch(
      readingProgressProvider(comicId: id).future,
    );
    final images = await ref.watch(comicImagesProvider(comicId: id).future);
    final totalPages = images.length;
    final oneBased = (progress?.pageIndex ?? 1).clamp(
      1,
      totalPages > 0 ? totalPages : 1,
    );
    return ReaderViewState(
      comic: comic,
      currentIndex: oneBased,
      totalPagesOverride: totalPages > 0 ? totalPages : null,
    );
  }

  void _updateDataState(ReaderViewState Function(ReaderViewState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  void toggleShowControls() {
    _updateDataState((s) => s.copyWith(showControls: !s.showControls));
  }

  void setShowControls(bool value) {
    _updateDataState((s) => s.copyWith(showControls: value));
  }

  void setIsVertical(bool value) {
    _updateDataState((s) => s.copyWith(isVertical: value));
  }

  void nextPage() {
    _updateDataState((s) {
      if (s.currentIndex + 1 > s.totalPages) return s;
      return s.copyWith(currentIndex: s.currentIndex + 1);
    });
  }

  void prevPage() {
    _updateDataState((s) {
      if (s.currentIndex - 1 < 1) return s;
      return s.copyWith(currentIndex: s.currentIndex - 1);
    });
  }

  void setIndex(int index) {
    _updateDataState((s) {
      if (index < 1 || index > s.totalPages) return s;
      return s.copyWith(currentIndex: index);
    });
  }

  void setTotalPagesOverride(int? value) {
    _updateDataState((s) => s.copyWith(totalPagesOverride: value));
  }

  void handleTapZone(ReaderTapZone zone) {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.showControls) {
      toggleShowControls();
      return;
    }
    if (current.isVertical) {
      _handleVerticalTap();
    } else {
      _handleHorizontalTap(zone);
    }
  }

  void _handleVerticalTap() {
    toggleShowControls();
  }

  void _handleHorizontalTap(ReaderTapZone zone) {
    if (zone == ReaderTapZone.left) {
      prevPage();
    } else if (zone == ReaderTapZone.right) {
      nextPage();
    } else {
      toggleShowControls();
    }
  }

  Future<void> executeSaveProgress({
    required ReaderRouteContext routeContext,
  }) async {
    final ReaderViewState? currentState = state.asData?.value;
    if (currentState == null) {
      return;
    }
    await ref
        .read(readingAggregateProvider.notifier)
        .saveProgress(
          comicId: id,
          comic: currentState.comic,
          pageIndex: currentState.currentIndex,
          isSeriesMode: routeContext.isSeriesMode,
          seriesName: routeContext.seriesName,
        );
  }

  Future<void> executeExitReader({
    required BuildContext context,
    required ReaderRouteContext routeContext,
  }) async {
    await ref
        .read(readerWindowFullscreenProvider.notifier)
        .exitFullscreenIfNeeded();
    await executeSaveProgress(routeContext: routeContext);
    if (!context.mounted) {
      return;
    }
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final String? seriesName = routeContext.isSeriesMode
        ? routeContext.seriesName
        : null;
    if (seriesName != null) {
      router.goNamed(
        '系列详情',
        pathParameters: <String, String>{'name': seriesName},
      );
      return;
    }
    router.go('/home');
  }

  Future<void> executeSelectComic({
    required BuildContext context,
    required ReaderRouteContext routeContext,
    required String targetComicId,
  }) async {
    await executeSaveProgress(routeContext: routeContext);
    if (!context.mounted) {
      return;
    }
    final bool isSeriesMode = routeContext.isSeriesMode;
    context.pushReplacementNamed(
      ReaderRouteArgs.readerRouteName,
      queryParameters: ReaderRouteArgs(
        comicId: targetComicId,
        readType: isSeriesMode
            ? ReaderRouteArgs.readTypeSeries
            : ReaderRouteArgs.readTypeComic,
        seriesName: routeContext.seriesName,
        keepControlsOpen: true,
      ).toQueryParameters(),
    );
  }

  Future<void> executeSelectSeriesComic({
    required BuildContext context,
    required ReaderRouteContext routeContext,
    required String targetComicId,
    required String seriesName,
  }) async {
    await executeSelectComic(
      context: context,
      routeContext: routeContext,
      targetComicId: targetComicId,
    );
  }
}

@Riverpod()
Future<List<ReaderPageImageData>> comicImages(
  Ref ref, {
  required String comicId,
  String? chapterId,
}) async {
  final v2Comic = await ref.read(comicRepoProvider).findById(comicId);
  if (v2Comic == null) return [];

  final ComicReadResourceSessionManager sessions = ref.read(
    comicReadResourceSessionManagerProvider,
  );
  try {
    final accessor = await sessions.acquire(
      comicId: comicId,
      path: v2Comic.path,
      type: v2Comic.resourceType,
    );
    final int total = accessor.pageCount;
    if (total <= 0) {
      return const <ReaderPageImageData>[];
    }
    if (v2Comic.resourceType == ResourceType.dir) {
      final List<ReaderPageImageData> result = <ReaderPageImageData>[];
      for (int i = 0; i < total; i++) {
        final ReaderImage img = await accessor.getPageImage(i);
        if (img is ReaderFileImage) {
          result.add(ReaderDirPageImageData(img.file));
        }
      }
      return List<ReaderPageImageData>.unmodifiable(result);
    }
    final List<ReaderPageImageData> result = <ReaderPageImageData>[];
    for (int i = 0; i < total; i++) {
      result.add(ReaderArchivePageImageData(comicId: comicId, pageIndex: i));
    }
    return List<ReaderPageImageData>.unmodifiable(result);
  } catch (e, st) {
    LogManager.instance.handle(
      e,
      st,
      '加载漫画图片失败: comicId=$comicId, path=${v2Comic.path}, type=${v2Comic.resourceType}',
    );
    return [];
  }
}

@Riverpod()
Future<ComicCoverDisplayData?> comicCoverDisplay(
  Ref ref, {
  required String comicId,
}) async {
  final Comic? v2Comic = await ref.read(comicRepoProvider).findById(comicId);
  if (v2Comic == null) {
    return null;
  }
  final ResourceType resourceType = v2Comic.resourceType;
  if (resourceType == ResourceType.epub ||
      resourceType == ResourceType.zip ||
      resourceType == ResourceType.cbz) {
    try {
      final String sourceNorm = normalizeArchiveCoverSourcePath(v2Comic.path);
      final bool useDiskCache = ref.read(archiveCoverDiskCacheEnabledProvider);
      final ArchiveCoverCache coverCache = ref.read(archiveCoverCacheProvider);
      if (useDiskCache) {
        final String? cachedPath = await coverCache.tryReadValidPath(
          comicId: comicId,
          sourcePathNormalized: sourceNorm,
        );
        if (cachedPath != null) {
          return ComicCoverDisplayData.file(cachedPath);
        }
      }
      final ArchiveCoverDecodeResult decoded =
          await loadArchiveCoverDecodeResultOffMainUi(
            path: v2Comic.path,
            type: resourceType,
          );
      final Uint8List? bytes = decoded.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        if (useDiskCache) {
          final String? writtenPath = await coverCache.write(
            comicId: comicId,
            sourcePathNormalized: sourceNorm,
            bytes: bytes,
            fileExtension: decoded.fileExtension,
          );
          if (writtenPath != null) {
            return ComicCoverDisplayData.file(writtenPath);
          }
        }
        return ComicCoverDisplayData.bytes(bytes);
      }
      return null;
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '加载漫画封面失败(isolate): comicId=$comicId, path=${v2Comic.path}, type=$resourceType',
      );
      return null;
    }
  }
  final ComicReadResourceSessionManager sessions = ref.read(
    comicReadResourceSessionManagerProvider,
  );
  try {
    final ComicReadResourceAccessor accessor = await sessions.acquire(
      comicId: comicId,
      path: v2Comic.path,
      type: resourceType,
    );
    final ReaderImage cover = await accessor.getCoverImage();
    if (cover is ReaderFileImage) {
      return ComicCoverDisplayData.file(cover.file.path);
    }
    if (cover is ReaderBytesImage) {
      return ComicCoverDisplayData.bytes(cover.bytes);
    }
    return null;
  } catch (e, st) {
    LogManager.instance.handle(
      e,
      st,
      '加载漫画封面失败: comicId=$comicId, path=${v2Comic.path}, type=${v2Comic.resourceType}',
    );
    return null;
  }
}

@Riverpod()
Future<Uint8List?> comicReaderPageBytes(
  Ref ref, {
  required String comicId,
  required int pageIndex,
}) async {
  final Comic? v2Comic = await ref.read(comicRepoProvider).findById(comicId);
  if (v2Comic == null) {
    return null;
  }
  if (v2Comic.resourceType == ResourceType.dir) {
    return null;
  }
  final ComicReadResourceSessionManager sessions = ref.read(
    comicReadResourceSessionManagerProvider,
  );
  try {
    final ComicReadResourceAccessor accessor = await sessions.acquire(
      comicId: comicId,
      path: v2Comic.path,
      type: v2Comic.resourceType,
    );
    final ReaderImage img = await accessor.getPageImage(pageIndex);
    if (img is ReaderBytesImage) {
      return img.bytes;
    }
    if (img is ReaderFileImage) {
      return img.file.readAsBytes();
    }
    return null;
  } catch (e, st) {
    LogManager.instance.handle(
      e,
      st,
      '加载漫画页面字节失败: comicId=$comicId pageIndex=$pageIndex',
    );
    return null;
  }
}

@Riverpod()
Future<entity.ReadingHistory?> readingProgress(
  Ref ref, {
  required String comicId,
}) async {
  final repo = ref.watch(readingHistoryRepoProvider);
  return repo.getByComicId(comicId);
}
