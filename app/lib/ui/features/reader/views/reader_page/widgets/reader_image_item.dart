import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderImageItem extends ConsumerStatefulWidget {
  const ReaderImageItem({
    super.key,
    required this.imageData,
    required this.slotLogicalWidth,
    this.enableCrossfade = false,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
  });

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
  String? _checkedCachePath;
  String? _reloadedMissingCachePath;

  @override
  void didUpdateWidget(ReaderImageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData) {
      _reloadScheduled = false;
      _checkedCachePath = null;
      _reloadedMissingCachePath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget loadingSurface = _buildReaderLoadingSurface(context);
    final Widget errorPlaceholder = _buildReaderImageErrorPlaceholder(context);
    final ReaderPageImageData imageData = widget.imageData;
    final int? cacheWidth = _readerDecodeCacheWidth(context);
    final FilterQuality filterQuality = readerImageFilterQuality(
      isScrolling: ReaderScrollActivity.isScrollingOf(context),
    );

    if (imageData is ReaderDirPageImageData) {
      final String dirPath = imageData.file.path.trim();
      if (dirPath.isEmpty) {
        return errorPlaceholder;
      }
      return ReaderPageFadeIn(
        enabled: widget.enableCrossfade,
        child: Align(
          alignment: widget.alignment,
          child: AppComicImage(
            filePath: imageData.file.path,
            fit: widget.fit,
            filterQuality: filterQuality,
            useReaderImageCache: true,
            cacheWidth: cacheWidth,
            loadingPlaceholder: loadingSurface,
            errorPlaceholder: errorPlaceholder,
          ),
        ),
      );
    }
    if (imageData is! ReaderArchivePageImageData) {
      return errorPlaceholder;
    }
    final ReaderArchivePageImageData archiveData = imageData;
    final AsyncValue<ReaderPagePayload> pageAsync = ref.watch(
      comicReaderPageProvider(
        comicId: archiveData.comicId,
        pageIndex: archiveData.pageIndex,
      ),
    );
    return pageAsync.when(
      loading: () => loadingSurface,
      error: (_, StackTrace _) => errorPlaceholder,
      data: (ReaderPagePayload page) {
        return switch (page) {
          ReaderPageFilePath(:final String path) =>
            _buildArchiveFilePathPage(
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
                memoryBytes: data,
                fit: widget.fit,
                filterQuality: filterQuality,
                useReaderImageCache: true,
                cacheWidth: cacheWidth,
                loadingPlaceholder: loadingSurface,
                errorPlaceholder: errorPlaceholder,
              ),
            ),
          ),
        };
      },
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
    // One-shot per path: keepAlive may still hold FilePath after disk eviction.
    // Avoid handing a missing path to ExtendedImage (can stick in LoadState.loading).
    if (_reloadScheduled) {
      return loadingSurface;
    }
    if (_checkedCachePath != path) {
      _checkedCachePath = path;
      if (!File(path).existsSync()) {
        if (_reloadedMissingCachePath == path) {
          // Already invalidated once for this path; don't loop forever.
          return errorPlaceholder;
        }
        _reloadedMissingCachePath = path;
        _scheduleReaderPageReload(archiveData);
        return loadingSurface;
      }
    }
    return ReaderPageFadeIn(
      enabled: widget.enableCrossfade,
      child: Align(
        alignment: widget.alignment,
        child: AppComicImage(
          filePath: path,
          fit: widget.fit,
          filterQuality: filterQuality,
          useReaderImageCache: true,
          cacheWidth: cacheWidth,
          loadingPlaceholder: loadingSurface,
          errorPlaceholder: errorPlaceholder,
          onDecodeError: () => _scheduleReaderPageReload(archiveData),
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

  void _scheduleReaderPageReload(ReaderArchivePageImageData archiveData) {
    if (_reloadScheduled) {
      return;
    }
    _reloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadScheduled = false;
      _checkedCachePath = null;
      if (!mounted) {
        return;
      }
      ref.invalidate(
        comicReaderPageProvider(
          comicId: archiveData.comicId,
          pageIndex: archiveData.pageIndex,
        ),
      );
    });
  }

  Widget _buildReaderLoadingSurface(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.hentai.readerBackground,
    );
  }

  Widget _buildReaderImageErrorPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Icon(
        LucideIcons.bookImage,
        size: 24,
        color: Theme.of(context).colorScheme.hentai.readerTextMuted,
      ),
    );
  }
}
