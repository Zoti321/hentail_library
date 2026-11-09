import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_prefetch_notifier.dart';
import 'package:hentai_library/features/reader/domain/page_prefetch_window.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void useReaderPrefetchWindow({
  required WidgetRef ref,
  required BuildContext context,
  required String comicId,
  required int centerPageOneBased,
  required int totalPages,
  required double slotLogicalWidth,
  required List<ReaderPageImageData> imageList,
  List<int> extraPageIndexesOneBased = const <int>[],
}) {
  useEffect(
    () {
      if (totalPages <= 0) {
        return null;
      }
      final Set<int> targets = computePrefetchWindow(
        centerPageOneBased: centerPageOneBased,
        totalPages: totalPages,
        neighborCount: kReaderPrefetchNeighborCount,
        extraPageIndexesOneBased: extraPageIndexesOneBased,
      );
      final int? cacheWidth = decodeCacheSizeForContext(
        context,
        logicalWidth: slotLogicalWidth,
        logicalHeight: slotLogicalWidth,
      ).cacheWidth;
      final ReaderPrefetchNotifier controller = ref.read(
        readerPrefetchNotifierProvider.notifier,
      );
      // Defer warmWindow: useEffect can run during hook init/build, and
      // bumpGeneration must not modify providers mid-build (Riverpod assert).
      // Also lets viewport jumpToPage mount the landing page first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        unawaited(() async {
          final bool windowChanged = await controller.warmWindow(
            comicId: comicId,
            centerPageOneBased: centerPageOneBased,
            totalPages: totalPages,
            extraPageIndexesOneBased: extraPageIndexesOneBased,
            imageList: imageList,
          );
          if (!context.mounted || !windowChanged) {
            return;
          }
          await controller.precacheWindow(
            context: context,
            comicId: comicId,
            pageIndexesOneBased: targets,
            imageList: imageList,
            cacheWidth: cacheWidth,
            skipPageOneBased: centerPageOneBased,
          );
        }());
      });
      return null;
    },
    <Object?>[
      comicId,
      centerPageOneBased,
      totalPages,
      slotLogicalWidth,
      MediaQuery.devicePixelRatioOf(context),
      Object.hashAll(extraPageIndexesOneBased),
      Object.hashAll(
        imageList.map((ReaderPageImageData data) => data.hashCode),
      ),
    ],
  );
}
