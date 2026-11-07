import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/read_session/presentation/widgets/viewport/reader_prefetch_hook.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Watches [currentIndex] only for prefetch; keeps list/PageView free of that subscription.
class ReaderViewportPrefetchBinder extends HookConsumerWidget {
  const ReaderViewportPrefetchBinder({
    super.key,
    required this.viewKey,
    required this.comicId,
    required this.totalPages,
    required this.slotLogicalWidth,
    required this.imageList,
    this.extraPageIndexesOneBased = const <int>[],
  });

  final ReaderControllerKey viewKey;
  final String comicId;
  final int totalPages;
  final double slotLogicalWidth;
  final List<ReaderPageImageData> imageList;
  final List<int> extraPageIndexesOneBased;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> value) =>
            value.asData?.value.currentIndex ?? 1,
      ),
    );
    useReaderPrefetchWindow(
      ref: ref,
      context: context,
      comicId: comicId,
      centerPageOneBased: currentIndex,
      totalPages: totalPages,
      slotLogicalWidth: slotLogicalWidth,
      imageList: imageList,
      extraPageIndexesOneBased: extraPageIndexesOneBased,
    );
    return const SizedBox.shrink();
  }
}
