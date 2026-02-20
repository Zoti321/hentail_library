import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/image/image_quality_policy.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ReaderVerticalContent extends HookConsumerWidget {
  const ReaderVerticalContent({
    super.key,
    required this.comicId,
    required this.preferredPageIndex,
  });
  final String comicId;
  final int? preferredPageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(
      readerViewProvider(comicId).select(
        (AsyncValue<ReaderViewState> value) =>
            value.asData?.value.currentIndex ?? 1,
      ),
    );

    final images = ref
        .watch(comicImagesProvider(comicId: comicId))
        .asData
        ?.value;
    final List<ReaderPageImageData> imageList =
        images ?? const <ReaderPageImageData>[];

    final ReaderViewNotifier notifier = ref.read(
      readerViewProvider(comicId).notifier,
    );
    final ItemScrollController itemScrollController = useMemoized(
      ItemScrollController.new,
    );
    final ItemPositionsListener itemPositionsListener = useMemoized(
      ItemPositionsListener.create,
    );

    final ObjectRef<int?> lastPrecachedCenterIndex = useRef<int?>(null);
    final ObjectRef<int?> lastVisibleMainIndex = useRef<int?>(null);
    final ObjectRef<bool> isProgrammaticScroll = useRef<bool>(false);
    final ObjectRef<bool> hasAppliedPreferredPage = useRef<bool>(false);
    final Size viewportSize = MediaQuery.sizeOf(context);
    final ImageQualityPolicy imageQualityPolicy = ImageQualityPolicy.current;
    Future<void> executeScrollToIndex(int targetIndexOneBased) async {
      if (!itemScrollController.isAttached) {
        return;
      }
      isProgrammaticScroll.value = true;
      try {
        await itemScrollController.scrollTo(
          index: targetIndexOneBased - 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0,
        );
        lastVisibleMainIndex.value = targetIndexOneBased;
      } finally {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          isProgrammaticScroll.value = false;
        });
      }
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
          notifier.setIndex(safeIndex);
        });
        return null;
      },
      <Object?>[
        comicId,
        preferredPageIndex,
        imageList.length,
        currentIndex,
        notifier,
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
          notifier.setIndex(visibleIndexOneBased);
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
        notifier,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        unawaited(executeScrollToIndex(safeIndex));
      });
      return null;
    }, <Object?>[currentIndex, imageList.length]);
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
        constraints: BoxConstraints(
          maxWidth: (viewportSize.width * 0.8).clamp(480.0, 1600.0).toDouble(),
        ),
        child: ScrollablePositionedList.builder(
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          physics: const ClampingScrollPhysics(),
          itemCount: imageList.length,
          itemBuilder: (BuildContext context, int index) {
            final ReaderPageImageData imageData = imageList[index];
            return ReaderImageItem(imageData: imageData);
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
