import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_page_fade_in.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderImageItem extends ConsumerWidget {
  const ReaderImageItem({
    super.key,
    required this.imageData,
    this.enableCrossfade = false,
  });

  final ReaderPageImageData imageData;
  final bool enableCrossfade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageData is ReaderDirPageImageData) {
      final ReaderDirPageImageData dirData =
          imageData as ReaderDirPageImageData;
      return ReaderPageFadeIn(
        enabled: enableCrossfade,
        child: Image.file(
          dirData.file,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return _buildReaderImagePlaceholder(context);
              },
        ),
      );
    }
    if (imageData is! ReaderArchivePageImageData) {
      return _buildReaderImagePlaceholder(context);
    }
    final ReaderArchivePageImageData archiveData =
        imageData as ReaderArchivePageImageData;
    ref.watch(readerPrefetchControllerProvider);
    final Uint8List? prefetchedBytes = ref
        .read(readerPrefetchControllerProvider.notifier)
        .cachedBytes(
          comicId: archiveData.comicId,
          archivePageIndex: archiveData.pageIndex,
        );
    final Uint8List? imageBytes =
        prefetchedBytes ??
        ref
            .watch(
              comicReaderPageBytesProvider(
                comicId: archiveData.comicId,
                pageIndex: archiveData.pageIndex,
              ),
            )
            .asData
            ?.value;
    if (imageBytes != null) {
      return ReaderPageFadeIn(
        enabled: enableCrossfade,
        child: Image(
          image: MemoryImage(imageBytes),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return _buildReaderImagePlaceholder(context);
              },
        ),
      );
    }
    return _buildReaderImagePlaceholder(context);
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
