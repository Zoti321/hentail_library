import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_prefetch_hook.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ContinuousVerticalViewport extends HookConsumerWidget {
  const ContinuousVerticalViewport({
    super.key,
    required this.comicId,
    required this.incognito,
    required this.preferredPageIndex,
  });

  final String comicId;
  final bool incognito;
  final int? preferredPageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderControllerKey viewKey = readerControllerKey(
      comicId,
      incognito: incognito,
    );
    final int currentIndex = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> value) =>
            value.asData?.value.currentIndex ?? 1,
      ),
    );

    final images = ref
        .watch(comicImagesProvider(comicId: comicId))
        .asData
        ?.value;
    final List<ReaderPageImageData> imageList =
        images ?? const <ReaderPageImageData>[];

    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
    );
    final ItemScrollController itemScrollController = useMemoized(
      ItemScrollController.new,
    );
    final ItemPositionsListener itemPositionsListener = useMemoized(
      ItemPositionsListener.create,
    );

    final ObjectRef<bool> hasAppliedPreferredPage = useRef<bool>(false);
    final ObjectRef<int?> lastVisibleMainIndex = useRef<int?>(null);
    final ObjectRef<bool> isProgrammaticScroll = useRef<bool>(false);
    final ObjectRef<int> scrollGeneration = useRef<int>(0);
    final Size viewportSize = MediaQuery.sizeOf(context);
    final int totalPages = imageList.length;

    useReaderPrefetchWindow(
      ref: ref,
      context: context,
      comicId: comicId,
      centerPageOneBased: currentIndex,
      totalPages: totalPages,
      slotLogicalWidth: readerContinuousSlotLogicalWidth(viewportSize.width),
      imageList: imageList,
    );
    void executeScrollToIndex(int targetIndexOneBased) {
      if (!context.mounted || !itemScrollController.isAttached) {
        return;
      }
      isProgrammaticScroll.value = true;
      itemScrollController.jumpTo(
        index: targetIndexOneBased - 1,
        alignment: 0,
      );
      lastVisibleMainIndex.value = targetIndexOneBased;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        isProgrammaticScroll.value = false;
      });
    }

    useEffect(() {
      hasAppliedPreferredPage.value = false;
      return null;
    }, <Object?>[comicId, preferredPageIndex]);
    useEffect(
      () {
        final int? preferred = preferredPageIndex;
        if (preferred == null ||
            hasAppliedPreferredPage.value ||
            imageList.isEmpty) {
          return null;
        }
        final int safeIndex = preferred.clamp(1, imageList.length);
        hasAppliedPreferredPage.value = true;
        if (safeIndex == currentIndex) {
          return null;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          controller.setIndex(safeIndex);
        });
        return null;
      },
      <Object?>[
        comicId,
        preferredPageIndex,
        imageList.length,
        currentIndex,
        controller,
      ],
    );

    useEffect(
      () {
        void handleVisiblePositionChange() {
          if (isProgrammaticScroll.value || imageList.isEmpty) {
            return;
          }
          final int? visibleIndex = _resolvePrimaryVisibleIndex(
            itemPositionsListener.itemPositions.value,
          );
          if (visibleIndex == null) {
            return;
          }
          final int visibleIndexOneBased = visibleIndex + 1;
          if (lastVisibleMainIndex.value == visibleIndexOneBased) {
            return;
          }
          lastVisibleMainIndex.value = visibleIndexOneBased;
          if (currentIndex == visibleIndexOneBased) {
            return;
          }
          controller.setIndex(visibleIndexOneBased);
        }

        itemPositionsListener.itemPositions.addListener(
          handleVisiblePositionChange,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          handleVisiblePositionChange();
        });
        return () {
          itemPositionsListener.itemPositions.removeListener(
            handleVisiblePositionChange,
          );
        };
      },
      <Object?>[
        itemPositionsListener,
        imageList.length,
        currentIndex,
        controller,
      ],
    );
    useEffect(() {
      if (imageList.isEmpty) {
        lastVisibleMainIndex.value = null;
        isProgrammaticScroll.value = false;
        return null;
      }
      final int safeIndex = currentIndex.clamp(1, imageList.length);
      if (safeIndex == lastVisibleMainIndex.value) {
        return null;
      }
      final bool shouldSkipInitialTopScroll =
          safeIndex == 1 && lastVisibleMainIndex.value == null;
      if (shouldSkipInitialTopScroll) {
        return null;
      }
      final int generation = ++scrollGeneration.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || generation != scrollGeneration.value) {
          return;
        }
        if (!itemScrollController.isAttached) {
          return;
        }
        executeScrollToIndex(safeIndex);
      });
      return () {
        scrollGeneration.value++;
        isProgrammaticScroll.value = false;
      };
    }, <Object?>[currentIndex, imageList.length]);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: readerContinuousSlotLogicalWidth(viewportSize.width),
        ),
        child: ScrollablePositionedList.builder(
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          physics: const ClampingScrollPhysics(),
          itemCount: imageList.length,
          itemBuilder: (BuildContext context, int index) {
            final ReaderPageImageData imageData = imageList[index];
            return ReaderImageItem(
              imageData: imageData,
              slotLogicalWidth: readerContinuousSlotLogicalWidth(
                MediaQuery.sizeOf(context).width,
              ),
              enableCrossfade: false,
            );
          },
        ),
      ),
    );
  }
}

int? _resolvePrimaryVisibleIndex(Iterable<ItemPosition> positions) {
  final List<ItemPosition> visiblePositions = positions.where((
    ItemPosition position,
  ) {
    return position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1;
  }).toList();
  if (visiblePositions.isEmpty) {
    return null;
  }
  final List<ItemPosition> nonNegativeLeadingCandidates = visiblePositions
      .where((ItemPosition position) => position.itemLeadingEdge >= -0.001)
      .toList();
  final List<ItemPosition> candidates = nonNegativeLeadingCandidates.isNotEmpty
      ? nonNegativeLeadingCandidates
      : visiblePositions;
  candidates.sort((ItemPosition left, ItemPosition right) {
    final double leftDistanceToTop = left.itemLeadingEdge.abs();
    final double rightDistanceToTop = right.itemLeadingEdge.abs();
    final int leadingEdgeCompare = leftDistanceToTop.compareTo(
      rightDistanceToTop,
    );
    if (leadingEdgeCompare != 0) {
      return leadingEdgeCompare;
    }
    final int visibleRatioCompare = _calculateVisibleRatio(
      right,
    ).compareTo(_calculateVisibleRatio(left));
    if (visibleRatioCompare != 0) {
      return visibleRatioCompare;
    }
    return left.index.compareTo(right.index);
  });
  return candidates.first.index;
}

double _calculateVisibleRatio(ItemPosition position) {
  final double visibleTopEdge = math.max(position.itemLeadingEdge, 0);
  final double visibleBottomEdge = math.min(position.itemTrailingEdge, 1);
  return (visibleBottomEdge - visibleTopEdge).clamp(0.0, 1.0);
}
