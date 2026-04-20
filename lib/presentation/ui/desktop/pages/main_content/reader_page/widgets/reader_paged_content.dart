import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/image/image_quality_policy.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReaderPagedContent extends HookConsumerWidget {
  const ReaderPagedContent({
    super.key,
    required this.comicId,
    required this.initialPage,
    required this.preferredPageIndex,
  });
  final String comicId;
  final int initialPage;
  final int? preferredPageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(
      readerViewProvider(comicId).select(
        (AsyncValue<ReaderViewState> value) =>
            value.asData?.value.currentIndex ?? 1,
      ),
    );
    final int totalPages = ref.watch(
      readerViewProvider(comicId).select(
        (AsyncValue<ReaderViewState> value) =>
            value.asData?.value.totalPages ?? 1,
      ),
    );
    final images = ref
        .watch(comicImagesProvider(comicId: comicId))
        .asData
        ?.value;
    final List<ReaderPageImageData> imageList =
        images ?? const <ReaderPageImageData>[];
    final Size viewportSize = MediaQuery.sizeOf(context);
    final ImageQualityPolicy imageQualityPolicy = ImageQualityPolicy.current;
    final PageController pageController = usePageController(
      initialPage: initialPage,
    );
    final ObjectRef<bool> hasAppliedPreferredPage = useRef<bool>(false);
    final ObjectRef<bool> isProgrammaticScroll = useRef<bool>(false);
    final ObjectRef<DateTime?> lastWheelAt = useRef<DateTime?>(null);
    final ObjectRef<int?> lastPrecachedCenterIndex = useRef<int?>(null);
    const int wheelThrottleMs = 200;
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
          ref.read(readerViewProvider(comicId).notifier).setIndex(safeIndex);
        });
      }
      return null;
    }, <Object?>[comicId, preferredPageIndex, totalPages, currentIndex]);
    useEffect(() {
      if (!pageController.hasClients) {
        return null;
      }
      final int targetPage = currentIndex - 1;
      final int currentPage =
          pageController.page?.round() ?? pageController.initialPage;
      if (currentPage == targetPage) {
        return null;
      }
      isProgrammaticScroll.value = true;
      pageController.jumpToPage(targetPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isProgrammaticScroll.value = false;
      });
      return null;
    }, <Object?>[currentIndex, pageController]);
    useEffect(() {
      if (imageList.isEmpty) {
        lastPrecachedCenterIndex.value = null;
        return null;
      }
      final int safeIndex = currentIndex.clamp(1, imageList.length);
      if (lastPrecachedCenterIndex.value == safeIndex) {
        return null;
      }
      lastPrecachedCenterIndex.value = safeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        ReaderImageItem.precacheNeighborPages(
          context: context,
          imageDataList: imageList,
          ref: ref,
          comicId: comicId,
          currentIndexOneBased: safeIndex,
          neighborCount: imageQualityPolicy.readerPrecacheNeighborCount,
        );
      });
      return null;
    }, <Object?>[currentIndex, imageList.length]);
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
            final ReaderViewNotifier notifier = ref.read(
              readerViewProvider(comicId).notifier,
            );
            if (dy > 0) {
              notifier.nextPage();
            } else {
              notifier.prevPage();
            }
          },
          child: PageView.builder(
            controller: pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (int index) {
              if (isProgrammaticScroll.value) {
                return;
              }
              ref
                  .read(readerViewProvider(comicId).notifier)
                  .setIndex(index + 1);
            },
            itemCount: imageList.length,
            itemBuilder: (BuildContext context, int index) {
              final ReaderPageImageData imageData = imageList[index];
              return ReaderImageItem(imageData: imageData);
            },
          ),
        ),
      ),
    );
  }
}
