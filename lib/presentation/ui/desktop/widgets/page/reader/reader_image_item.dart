import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_page_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderImageItem extends ConsumerWidget {
  const ReaderImageItem({super.key, required this.imageData});
  final ReaderPageImageData imageData;

  static Future<void> precacheNeighborPages({
    required BuildContext context,
    required List<ReaderPageImageData> imageDataList,
    required WidgetRef ref,
    required String comicId,
    required int currentIndexOneBased,
    int neighborCount = 1,
  }) async {
    if (imageDataList.isEmpty) {
      return;
    }
    final int safeIndex = currentIndexOneBased.clamp(1, imageDataList.length);
    final Set<int> targetIndexes = <int>{};
    for (int offset = 1; offset <= neighborCount; offset++) {
      final int prev = safeIndex - offset;
      final int next = safeIndex + offset;
      if (prev >= 1) {
        targetIndexes.add(prev - 1);
      }
      if (next <= imageDataList.length) {
        targetIndexes.add(next - 1);
      }
    }
    for (final int index in targetIndexes) {
      final ReaderPageImageData imageData = imageDataList[index];
      try {
        late final ImageProvider provider;
        if (imageData is ReaderDirPageImageData) {
          provider = FileImage(imageData.file);
        } else if (imageData is ReaderArchivePageImageData) {
          final Uint8List? bytes = await ref.read(
            comicReaderPageBytesProvider(
              comicId: imageData.comicId,
              pageIndex: imageData.pageIndex,
            ).future,
          );
          if (bytes == null) {
            continue;
          }
          provider = MemoryImage(bytes);
        } else {
          continue;
        }
        if (!context.mounted) {
          return;
        }
        await precacheImage(provider, context);
      } catch (_) {
        // Ignore decode failures for pre-cache warm-up.
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageData is ReaderDirPageImageData) {
      final ReaderDirPageImageData dirData =
          imageData as ReaderDirPageImageData;
      return Image.file(
        dirData.file,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return _buildReaderImagePlaceholder(context);
            },
      );
    }
    if (imageData is! ReaderArchivePageImageData) {
      return _buildReaderImagePlaceholder(context);
    }
    final ReaderArchivePageImageData archiveData =
        imageData as ReaderArchivePageImageData;
    final Uint8List? imageBytes = ref
        .watch(
          comicReaderPageBytesProvider(
            comicId: archiveData.comicId,
            pageIndex: archiveData.pageIndex,
          ),
        )
        .asData
        ?.value;
    if (imageBytes != null) {
      return Image(
        image: MemoryImage(imageBytes),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return _buildReaderImagePlaceholder(context);
            },
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
        color: Theme.of(context).colorScheme.readerTextMuted,
      ),
    );
  }
}
