import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_prefetch_hook.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/reading/spread_index.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DualPageViewport extends HookConsumerWidget {
  const DualPageViewport({
    super.key,
    required this.comicId,
    required this.incognito,
    required this.readingMode,
    required this.initialPage,
    required this.preferredPageIndex,
    this.onRequestNextPage,
  });

  final String comicId;
  final bool incognito;
  final ReadingMode readingMode;
  final int initialPage;
  final int? preferredPageIndex;
  final Future<void> Function()? onRequestNextPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderControllerKey viewKey = readerControllerKey(
      comicId,
      incognito: incognito,
    );
    final ReaderState? readerState = ref
        .watch(readerControllerProvider(viewKey))
        .asData
        ?.value;
    final int currentIndex = readerState?.currentIndex ?? 1;
    final int totalPages = readerState?.totalPages ?? 1;
    final ReadingMode activeMode = readerState?.readingMode ?? readingMode;
    final images = ref
        .watch(comicImagesProvider(comicId: comicId))
        .asData
        ?.value;
    final List<ReaderPageImageData> imageList =
        images ?? const <ReaderPageImageData>[];
    final int spreadCount = SpreadIndex.totalSpreads(
      mode: activeMode,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
    final int initialSpread = SpreadIndex.spreadIndexForPage(
      mode: activeMode,
      totalPages: totalPages > 0 ? totalPages : 1,
      pageIndex: initialPage + 1,
    );
    final Size viewportSize = MediaQuery.sizeOf(context);
    final PageController pageController = usePageController(
      initialPage: initialSpread,
    );
    final ObjectRef<bool> hasAppliedPreferredPage = useRef<bool>(false);
    final ObjectRef<bool> isProgrammaticScroll = useRef<bool>(false);
    final ObjectRef<DateTime?> lastWheelAt = useRef<DateTime?>(null);
    const int wheelThrottleMs = 200;

    final int currentSpread = SpreadIndex.spreadIndexForPage(
      mode: activeMode,
      totalPages: totalPages > 0 ? totalPages : 1,
      pageIndex: currentIndex,
    );
    final int safeTotalPages = totalPages > 0 ? totalPages : 1;
    final List<int> spreadPages = SpreadIndex.pagesInSpread(
      mode: activeMode,
      totalPages: safeTotalPages,
      spreadIndex: currentSpread,
    );

    useReaderPrefetchWindow(
      ref: ref,
      context: context,
      comicId: comicId,
      centerPageOneBased: currentIndex,
      totalPages: safeTotalPages,
      slotLogicalWidth: readerDualPageSlotLogicalWidth(viewportSize.width),
      imageList: imageList,
      extraPageIndexesOneBased: spreadPages,
    );

    useEffect(() {
      hasAppliedPreferredPage.value = false;
      return null;
    }, <Object?>[comicId, preferredPageIndex]);
    useEffect(() {
      final int? preferred = preferredPageIndex;
      if (preferred == null || hasAppliedPreferredPage.value) {
        return null;
      }
      final int safeTotalPages = totalPages > 0 ? totalPages : 1;
      final int safeIndex = preferred.clamp(1, safeTotalPages);
      hasAppliedPreferredPage.value = true;
      if (currentIndex != safeIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          ref
              .read(readerControllerProvider(viewKey).notifier)
              .setIndex(safeIndex);
        });
      }
      return null;
    }, <Object?>[comicId, preferredPageIndex, totalPages, currentIndex]);
    useEffect(() {
      if (!pageController.hasClients) {
        return null;
      }
      if (pageController.page?.round() == currentSpread) {
        return null;
      }
      isProgrammaticScroll.value = true;
      pageController
          .animateToPage(
            currentSpread,
            duration: kReaderPageTurnAnimationDuration,
            curve: Curves.easeInOut,
          )
          .whenComplete(() {
            if (context.mounted) {
              isProgrammaticScroll.value = false;
            }
          });
      return null;
    }, <Object?>[currentSpread, pageController]);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: viewportSize.width),
        child: Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is! PointerScrollEvent) {
              return;
            }
            final double dy = event.scrollDelta.dy;
            if (dy == 0) {
              return;
            }
            final DateTime now = DateTime.now();
            final DateTime? last = lastWheelAt.value;
            if (last != null &&
                now.difference(last).inMilliseconds < wheelThrottleMs) {
              return;
            }
            lastWheelAt.value = now;
            final ReaderController controller = ref.read(
              readerControllerProvider(viewKey).notifier,
            );
            if (dy > 0) {
              if (onRequestNextPage != null) {
                unawaited(onRequestNextPage!());
              } else {
                controller.nextPage();
              }
            } else {
              controller.prevPage();
            }
          },
          child: PageView.builder(
            controller: pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (int spreadIndex) {
              if (isProgrammaticScroll.value) {
                return;
              }
              final int safeTotalPages = totalPages > 0 ? totalPages : 1;
              final int primaryPage = SpreadIndex.primaryPageForSpread(
                mode: activeMode,
                totalPages: safeTotalPages,
                spreadIndex: spreadIndex,
              );
              ref
                  .read(readerControllerProvider(viewKey).notifier)
                  .setIndex(primaryPage);
            },
            itemCount: spreadCount,
            itemBuilder: (BuildContext context, int spreadIndex) {
              final int safeTotalPages = totalPages > 0 ? totalPages : 1;
              final List<int> pages = SpreadIndex.pagesInSpread(
                mode: activeMode,
                totalPages: safeTotalPages,
                spreadIndex: spreadIndex,
              );
              return _DualSpreadPage(
                pages: pages,
                imageList: imageList,
                readingMode: activeMode,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DualSpreadPage extends StatelessWidget {
  const _DualSpreadPage({
    required this.pages,
    required this.imageList,
    required this.readingMode,
  });

  final List<int> pages;
  final List<ReaderPageImageData> imageList;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context) {
    final double slotLogicalWidth = readerDualPageSlotLogicalWidth(
      MediaQuery.sizeOf(context).width,
    );
    if (pages.isEmpty) {
      return const SizedBox.expand();
    }
    if (pages.length == 1) {
      final int pageIndex = pages.first;
      final ReaderPageImageData? imageData = _imageAt(pageIndex);
      if (imageData == null) {
        return const SizedBox.expand();
      }
      final bool coverOnRight =
          readingMode == ReadingMode.dualPageNoCover && pageIndex == 1;
      final Alignment alignment =
          coverOnRight ? Alignment.centerLeft : Alignment.centerRight;
      return Row(
        children: <Widget>[
          if (coverOnRight) const Expanded(child: SizedBox.shrink()),
          Expanded(
            child: ReaderImageItem(
              imageData: imageData,
              slotLogicalWidth: slotLogicalWidth,
              alignment: alignment,
              enableCrossfade: true,
            ),
          ),
          if (!coverOnRight) const Expanded(child: SizedBox.shrink()),
        ],
      );
    }
    final ReaderPageImageData? leftImage = _imageAt(pages.first);
    final ReaderPageImageData? rightImage = _imageAt(pages.last);
    return Row(
      children: <Widget>[
        Expanded(
          child: leftImage == null
              ? const SizedBox.shrink()
              : ReaderImageItem(
                  imageData: leftImage,
                  slotLogicalWidth: slotLogicalWidth,
                  alignment: Alignment.centerRight,
                  enableCrossfade: true,
                ),
        ),
        Expanded(
          child: rightImage == null
              ? const SizedBox.shrink()
              : ReaderImageItem(
                  imageData: rightImage,
                  slotLogicalWidth: slotLogicalWidth,
                  alignment: Alignment.centerLeft,
                  enableCrossfade: true,
                ),
        ),
      ],
    );
  }

  ReaderPageImageData? _imageAt(int oneBasedPageIndex) {
    final int index = oneBasedPageIndex - 1;
    if (index < 0 || index >= imageList.length) {
      return null;
    }
    return imageList[index];
  }
}
