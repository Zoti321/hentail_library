import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/context_menu/common.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/features/reader/di/page_image_copy_providers.dart';
import 'package:hentai_library/features/reader/presentation/image/reader_image_cache.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_image_filter_quality.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_page_fade_in.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_page_aspect_ratios.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_prefetch_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 磁盘缓存被预取窗口驱逐后，同路径 ExtendedImage 失败态不会自动重挂载；限制重试次数。
const int _kReaderPageReloadMaxAttempts = 3;

class ReaderImageItem extends ConsumerStatefulWidget {
  const ReaderImageItem({
    super.key,
    required this.comic,
    required this.imageData,
    required this.slotLogicalWidth,
    this.enableCrossfade = false,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
  });

  final Comic comic;
  final ReaderPageImageData imageData;
  final double slotLogicalWidth;
  final bool enableCrossfade;
  final Alignment alignment;
  final BoxFit fit;

  @override
  ConsumerState<ReaderImageItem> createState() => _ReaderImageItemState();
}

class _ReaderImageItemState extends ConsumerState<ReaderImageItem> {
  bool _reloadScheduled = false;
  int _reloadNonce = 0;
  int _reloadAttempts = 0;

  @override
  void didUpdateWidget(ReaderImageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData) {
      _reloadScheduled = false;
      _reloadAttempts = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget loadingSurface = _buildReaderLoadingSurface(context);
    final Widget errorPlaceholder = _buildReaderImageErrorPlaceholder(context);
    final ReaderPageImageData imageData = widget.imageData;
    final int? cacheWidth = _readerDecodeCacheWidth(context);
    const FilterQuality filterQuality = kReaderPageFilterQuality;

    if (imageData is ReaderDirPageImageData) {
      final String dirPath = imageData.file.path.trim();
      if (dirPath.isEmpty) {
        return _wrapWithContextMenu(context, errorPlaceholder);
      }
      return _wrapWithContextMenu(
        context,
        ReaderPageFadeIn(
          enabled: widget.enableCrossfade,
          child: Align(
            alignment: widget.alignment,
            child: AppComicImage(
              key: ValueKey<int>(_reloadNonce),
              filePath: imageData.file.path,
              fit: widget.fit,
              filterQuality: filterQuality,
              useReaderImageCache: true,
              readerImageProviderBuilder: buildReaderImageProvider,
              cacheWidth: cacheWidth,
              loadingPlaceholder: loadingSurface,
              errorPlaceholder: errorPlaceholder,
              onImageSize: _rememberImageSize,
            ),
          ),
        ),
      );
    }
    if (imageData is! ReaderArchivePageImageData) {
      return _wrapWithContextMenu(context, errorPlaceholder);
    }
    final ReaderArchivePageImageData archiveData = imageData;
    ref
        .read(readerPrefetchNotifierProvider.notifier)
        .notePageTouched(
          comicId: archiveData.comicId,
          pageOneBased: archiveData.pageIndex + 1,
        );
    final AsyncValue<ReaderPagePayload> pageAsync = ref.watch(
      comicReaderPageProvider(
        comicId: archiveData.comicId,
        pageIndex: archiveData.pageIndex,
      ),
    );
    // skipLoadingOnRefresh:false — invalidate 后必须卸掉失败态 ExtendedImage，
    // 否则同路径 FilePath 重解压后仍卡在 LoadState.failed（slider 大跳典型）。
    return pageAsync.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      loading: () => _wrapWithContextMenu(context, loadingSurface),
      error: (_, StackTrace _) {
        _scheduleReaderPageReload(archiveData);
        return _wrapWithContextMenu(context, errorPlaceholder);
      },
      data: (ReaderPagePayload page) {
        final Widget content = switch (page) {
          ReaderPageFilePath(:final String path) => _buildArchiveFilePathPage(
            archiveData: archiveData,
            path: path,
            loadingSurface: loadingSurface,
            errorPlaceholder: errorPlaceholder,
            filterQuality: filterQuality,
            cacheWidth: cacheWidth,
          ),
          ReaderPageBytes(:final Uint8List data) => ReaderPageFadeIn(
            enabled: widget.enableCrossfade,
            child: Align(
              alignment: widget.alignment,
              child: AppComicImage(
                key: ValueKey<int>(_reloadNonce),
                memoryBytes: data,
                fit: widget.fit,
                filterQuality: filterQuality,
                useReaderImageCache: true,
                readerImageProviderBuilder: buildReaderImageProvider,
                cacheWidth: cacheWidth,
                loadingPlaceholder: loadingSurface,
                errorPlaceholder: errorPlaceholder,
                onImageSize: _rememberImageSize,
              ),
            ),
          ),
        };
        return _wrapWithContextMenu(context, content);
      },
    );
  }

  void _rememberImageSize(Size size) {
    // AppComicImage reports size in a post-frame callback; the slot may
    // already be scrolled off and disposed.
    if (!mounted) {
      return;
    }
    ref
        .read(readerPageAspectRatiosProvider.notifier)
        .remember(
          comicId: widget.comic.comicId,
          pageIndexZeroBased: widget.imageData.archivePageIndex,
          width: size.width,
          height: size.height,
        );
  }

  Widget _wrapWithContextMenu(BuildContext context, Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (TapUpDetails details) {
        _showContextMenu(context, details.globalPosition);
      },
      onLongPressStart: (LongPressStartDetails details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  Widget _buildArchiveFilePathPage({
    required ReaderArchivePageImageData archiveData,
    required String path,
    required Widget loadingSurface,
    required Widget errorPlaceholder,
    required FilterQuality filterQuality,
    required int? cacheWidth,
  }) {
    // Disk may be gone after cache eviction while keepAlive still holds FilePath.
    if (_reloadScheduled) {
      return loadingSurface;
    }
    // 同步探测：避免先画出 error 图标再等 ExtendedImage failed 回调。
    if (!isUsableReaderCacheFile(path)) {
      _scheduleReaderPageReload(archiveData, stalePath: path);
      return loadingSurface;
    }
    return ReaderPageFadeIn(
      enabled: widget.enableCrossfade,
      child: Align(
        alignment: widget.alignment,
        child: AppComicImage(
          key: ValueKey<int>(_reloadNonce),
          filePath: path,
          fit: widget.fit,
          filterQuality: filterQuality,
          useReaderImageCache: true,
          readerImageProviderBuilder: buildReaderImageProvider,
          cacheWidth: cacheWidth,
          loadingPlaceholder: loadingSurface,
          errorPlaceholder: errorPlaceholder,
          onImageSize: _rememberImageSize,
          onDecodeError: () =>
              _scheduleReaderPageReload(archiveData, stalePath: path),
        ),
      ),
    );
  }

  int? _readerDecodeCacheWidth(BuildContext context) {
    return decodeCacheSizeForContext(
      context,
      logicalWidth: widget.slotLogicalWidth,
      logicalHeight: widget.slotLogicalWidth,
    ).cacheWidth;
  }

  void _scheduleReaderPageReload(
    ReaderArchivePageImageData archiveData, {
    String? stalePath,
  }) {
    if (_reloadScheduled || _reloadAttempts >= _kReaderPageReloadMaxAttempts) {
      return;
    }
    _reloadScheduled = true;
    _reloadAttempts += 1;
    // onDecodeError / error when() 可能在 build 中触发 — 延后 setState/invalidate。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runReaderPageReload(archiveData, stalePath: stalePath));
    });
  }

  Future<void> _runReaderPageReload(
    ReaderArchivePageImageData archiveData, {
    String? stalePath,
  }) async {
    try {
      if (!mounted) {
        return;
      }
      final String? path = stalePath?.trim();
      if (path != null && path.isNotEmpty) {
        await forgetReaderCachedFile(path);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _reloadNonce += 1;
      });
      ref.invalidate(
        comicReaderPageProvider(
          comicId: archiveData.comicId,
          pageIndex: archiveData.pageIndex,
        ),
      );
    } finally {
      // 允许后续 loading/error/data 再次调度重载。
      if (mounted) {
        _reloadScheduled = false;
      }
    }
  }

  Widget _buildReaderLoadingSurface(BuildContext context) {
    return ColoredBox(color: context.reader.readerPlaceholderSurface);
  }

  Widget _buildReaderImageErrorPlaceholder(BuildContext context) {
    return ColoredBox(
      color: context.reader.readerPlaceholderSurface,
      child: Center(
        child: Icon(
          Symbols.broken_image,
          size: 24,
          color: context.reader.readerTextMuted,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    ContextMenuCommon.show(
      context,
      position: position,
      width: 236,
      // Single action row (~36) + panel border; keep close to cursor when
      // clamped near the bottom edge.
      height: 48,
      builder: (VoidCallback onClose) => ContextMenuContainer(
        child: ContextMenuActionItem(
          icon: Symbols.content_copy,
          label: context.l10n.readerCopyPageImage,
          onTap: () {
            onClose();
            _copyPageImage(context);
          },
        ),
      ),
    );
  }

  Future<void> _copyPageImage(BuildContext context) async {
    try {
      await ref
          .read(copyPageImageServiceProvider)
          .execute(
            comic: widget.comic,
            archivePageIndex: widget.imageData.archivePageIndex,
          );
      if (context.mounted) {
        showSuccessSnackbar(context, context.l10n.readerCopyPageImageSuccess);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showErrorSnackbar(context, error);
      }
    }
  }
}
