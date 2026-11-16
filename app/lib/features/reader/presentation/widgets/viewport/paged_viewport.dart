import 'package:flutter/material.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/presentation/session/reader_session_bindings.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_image_item.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_page_crossfade_policy.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_kernel.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_pages.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_prefetch_binder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PagedViewport extends HookConsumerWidget {
  const PagedViewport({
    super.key,
    required this.comicId,
    required this.incognito,
    this.startFromFirstPage = false,
    required this.initialPage,
    required this.preferredPageIndex,
    this.onRequestNextPage,
    this.onRequestPrevPage,
  });

  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;
  final int initialPage;
  final int? preferredPageIndex;
  final Future<void> Function()? onRequestNextPage;
  final Future<void> Function()? onRequestPrevPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderViewModelKey viewKey = readerViewModelKey(
      comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
    final int totalPages = ref.watch(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> value) =>
            value.asData?.value.totalPages ?? 1,
      ),
    );
    final ReaderComicRef? comic = ref.watch(
      readerViewModelProvider(
        viewKey,
      ).select((AsyncValue<ReaderUiState> value) => value.asData?.value.comic),
    );
    if (comic == null) {
      return const SizedBox.expand();
    }
    final ReaderViewportPages resolvedPages = resolveReaderViewportPages(
      ref.watch(comicImagesProvider(comicId: comicId)),
    );
    final List<ReaderPageImageData> imageList = switch (resolvedPages) {
      ReaderViewportPagesReady(:final List<ReaderPageImageData> pages) => pages,
      ReaderViewportPagesLoading() ||
      ReaderViewportPagesError() ||
      ReaderViewportPagesEmpty() => const <ReaderPageImageData>[],
    };
    final double slotLogicalWidth = readerPagedSlotLogicalWidth(
      MediaQuery.sizeOf(context).width,
    );

    return ReaderPagedViewportKernel(
      viewKey: viewKey,
      comicId: comicId,
      comic: comic,
      totalPages: totalPages,
      imageList: imageList,
      initialPage: initialPage,
      initialItemIndex: initialPage,
      preferredPageIndex: preferredPageIndex,
      itemCount: imageList.length,
      itemIndexForPage: (int pageOneBased) => pageOneBased - 1,
      pageForItemIndex: (int itemIndex) => itemIndex + 1,
      slotLogicalWidth: slotLogicalWidth,
      itemBuilder:
          (
            BuildContext context,
            int index,
            ReaderComicRef comic,
            List<ReaderPageImageData> imageList,
            double slotLogicalWidth,
          ) => ReaderImageItem(
            comic: comic,
            imageData: imageList[index],
            slotLogicalWidth: slotLogicalWidth,
            enableCrossfade: readerPageCrossfadeEnabled(
              reduceMotion: MediaQuery.disableAnimationsOf(context),
            ),
          ),
      prefetchBinder: ReaderViewportPrefetchBinder(
        viewKey: viewKey,
        comicId: comicId,
        totalPages: totalPages,
        slotLogicalWidth: slotLogicalWidth,
        imageList: imageList,
      ),
      fallback: resolvedPages is ReaderViewportPagesReady
          ? null
          : ReaderViewportPagesFeedback(pages: resolvedPages),
      onRequestNextPage: onRequestNextPage,
      onRequestPrevPage: onRequestPrevPage,
    );
  }
}
