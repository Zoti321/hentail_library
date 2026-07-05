import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void useReaderPrefetchWindow({
  required WidgetRef ref,
  required String comicId,
  required int centerPageOneBased,
  required int totalPages,
  List<int> extraPageIndexesOneBased = const <int>[],
}) {
  useEffect(
    () {
      if (totalPages <= 0) {
        return null;
      }
      unawaited(
        ref
            .read(readerPrefetchControllerProvider.notifier)
            .warmWindow(
              comicId: comicId,
              centerPageOneBased: centerPageOneBased,
              totalPages: totalPages,
              extraPageIndexesOneBased: extraPageIndexesOneBased,
            ),
      );
      return null;
    },
    <Object?>[
      comicId,
      centerPageOneBased,
      totalPages,
      Object.hashAll(extraPageIndexesOneBased),
    ],
  );
}
