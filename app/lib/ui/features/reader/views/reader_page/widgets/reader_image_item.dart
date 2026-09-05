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

  @override
  void didUpdateWidget(ReaderImageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData) {
      _reloadScheduled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget loadingSurface = _buildReaderLoadingSurface(context);
    final Widget errorPlaceholder = _buildReaderImageErrorPlaceholder(context);
    final ReaderPageImageData imageData = widget.imageData;
    final int? cacheWidth = _readerDecodeCacheWidth(context);

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
            filterQuality: FilterQuality.high,
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
        return ReaderPageFadeIn(
          enabled: widget.enableCrossfade,
          child: Align(
            alignment: widget.alignment,
            child: switch (page) {
              ReaderPageFilePath(:final String path) => AppComicImage(
                filePath: path,
                fit: widget.fit,
                filterQuality: FilterQuality.high,
                useReaderImageCache: true,
                cacheWidth: cacheWidth,
                loadingPlaceholder: loadingSurface,
                errorPlaceholder: errorPlaceholder,
                onDecodeError: () => _scheduleReaderPageReload(archiveData),
              ),
              ReaderPageBytes(:final Uint8List data) => AppComicImage(
                memoryBytes: data,
                fit: widget.fit,
                filterQuality: FilterQuality.high,
                useReaderImageCache: true,
                cacheWidth: cacheWidth,
                loadingPlaceholder: loadingSurface,
                errorPlaceholder: errorPlaceholder,
              ),
            },
          ),
        );
      },
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
