import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hentai_library/src/rust/api/reader.dart';

class ReaderImageItem extends ConsumerWidget {
  const ReaderImageItem({
    super.key,
    required this.imageData,
    required this.slotLogicalWidth,
    this.enableCrossfade = false,
    this.alignment = Alignment.center,
  });

  final ReaderPageImageData imageData;
  final double slotLogicalWidth;
  final bool enableCrossfade;
  final Alignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cacheWidth = AppComicImage.resolveReaderCacheWidth(
      context: context,
      slotLogicalWidth: slotLogicalWidth,
    );
    final Widget placeholder = _buildReaderImagePlaceholder(context);

    if (imageData is ReaderDirPageImageData) {
      final ReaderDirPageImageData dirData =
          imageData as ReaderDirPageImageData;
      return ReaderPageFadeIn(
        enabled: enableCrossfade,
        child: Align(
          alignment: alignment,
          child: AppComicImage(
            filePath: dirData.file.path,
            fit: BoxFit.contain,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.high,
            useReaderImageCache: true,
            placeholder: placeholder,
            errorPlaceholder: placeholder,
          ),
        ),
      );
    }
    if (imageData is! ReaderArchivePageImageData) {
      return placeholder;
    }
    final ReaderArchivePageImageData archiveData =
        imageData as ReaderArchivePageImageData;
    final AsyncValue<ReaderPageDto> pageAsync = ref.watch(
      comicReaderPageProvider(
        comicId: archiveData.comicId,
        pageIndex: archiveData.pageIndex,
      ),
    );
    return pageAsync.when(
      loading: () => placeholder,
      error: (_, StackTrace _) => placeholder,
      data: (ReaderPageDto page) {
        return ReaderPageFadeIn(
          enabled: enableCrossfade,
          child: Align(
            alignment: alignment,
            child: page.when(
              filePath: (String path) => AppComicImage(
                filePath: path,
                fit: BoxFit.contain,
                cacheWidth: cacheWidth,
                filterQuality: FilterQuality.high,
                useReaderImageCache: true,
                placeholder: placeholder,
                errorPlaceholder: placeholder,
              ),
              bytes: (Uint8List data) => AppComicImage(
                memoryBytes: data,
                fit: BoxFit.contain,
                cacheWidth: cacheWidth,
                filterQuality: FilterQuality.high,
                useReaderImageCache: true,
                placeholder: placeholder,
                errorPlaceholder: placeholder,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReaderImagePlaceholder(BuildContext context) {
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
