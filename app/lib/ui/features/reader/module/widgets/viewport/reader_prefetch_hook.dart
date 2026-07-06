import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
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
      final ReaderPrefetchController controller = ref.read(
        readerPrefetchControllerProvider.notifier,
      );
      unawaited(
        controller.warmWindow(
          comicId: comicId,
          centerPageOneBased: centerPageOneBased,
          totalPages: totalPages,
          extraPageIndexesOneBased: extraPageIndexesOneBased,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        unawaited(
          controller.precacheWindow(
            context: context,
            comicId: comicId,
            pageIndexesOneBased: targets,
            imageList: imageList,
          ),
        );
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
      Object.hashAll(imageList.map((ReaderPageImageData data) => data.hashCode)),
    ],
  );
}
