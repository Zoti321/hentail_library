import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_prefetch_hook.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/resume_visible_sync_gate.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ContinuousVerticalViewport extends HookConsumerWidget {
  const ContinuousVerticalViewport({
    super.key,
    required this.comicId,
    required this.incognito,
    this.startFromFirstPage = false,
    required this.preferredPageIndex,
  });

  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;
  final int? preferredPageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderControllerKey viewKey = readerControllerKey(
      comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
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

    /// Blocks visible→index sync until resume target is actually on screen.
    final ObjectRef<ResumeVisibleSyncGate> resumeSyncGate =
        useRef<ResumeVisibleSyncGate>(ResumeVisibleSyncGate());
    final ObjectRef<int> scrollGeneration = useRef<int>(0);
    final ObjectRef<int?> frozenInitialScrollIndex = useRef<int?>(null);
    if (imageList.isNotEmpty && frozenInitialScrollIndex.value == null) {
      final int initialOneBased = currentIndex.clamp(1, imageList.length);
      frozenInitialScrollIndex.value = initialOneBased - 1;
      resumeSyncGate.value.beginProgrammaticAlign(
        targetOneBased: initialOneBased,
      );
    }
    final int initialScrollIndex = frozenInitialScrollIndex.value ?? 0;
    final Size viewportSize = MediaQuery.sizeOf(context);
    final int totalPages = imageList.length;
    final AppSetting? settings = ref.watch(settingsProvider).asData?.value;
    final int marginPercent =
        settings?.webtoonMarginPercent ?? kDefaultWebtoonMarginPercent;
    final WebtoonZoomMode zoomMode =
        settings?.webtoonZoomMode ?? kDefaultWebtoonZoomMode;
    final double slotLogicalWidth = zoomMode == WebtoonZoomMode.fitWidth
        ? readerContinuousSlotLogicalWidth(
            viewportSize.width,
            marginPercent: marginPercent,
          )
        : viewportSize.width;

    useReaderPrefetchWindow(
      ref: ref,
      context: context,
      comicId: comicId,
      centerPageOneBased: currentIndex,
      totalPages: totalPages,
      slotLogicalWidth: slotLogicalWidth,
      imageList: imageList,
    );
    void executeScrollToIndex(int targetIndexOneBased) {
      if (!context.mounted || !itemScrollController.isAttached) {
        return;
      }
      isProgrammaticScroll.value = true;
      resumeSyncGate.value.beginProgrammaticAlign(
        targetOneBased: targetIndexOneBased,
      );
      itemScrollController.jumpTo(index: targetIndexOneBased - 1, alignment: 0);
      lastVisibleMainIndex.value = targetIndexOneBased;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        isProgrammaticScroll.value = false;
      });
    }

    void scheduleScrollToIndex(int targetIndexOneBased, int generation) {
      void attempt() {
        if (!context.mounted || generation != scrollGeneration.value) {
          return;
        }
        if (!itemScrollController.isAttached) {
          WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
          return;
        }
        executeScrollToIndex(targetIndexOneBased);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
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
          final int? applyIndex = resumeSyncGate.value.onVisibleIndex(
            visibleIndexOneBased,
          );
          if (applyIndex == null) {
            return;
          }
          if (lastVisibleMainIndex.value == applyIndex) {
            return;
          }
          lastVisibleMainIndex.value = applyIndex;
          if (currentIndex == applyIndex) {
            return;
          }
          controller.setIndex(applyIndex);
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
        resumeSyncGate.value = ResumeVisibleSyncGate();
        return null;
      }
      final int safeIndex = currentIndex.clamp(1, imageList.length);
      if (safeIndex == lastVisibleMainIndex.value) {
        return null;
      }
      final bool shouldSkipInitialTopScroll =
          safeIndex == 1 && lastVisibleMainIndex.value == null;
      if (shouldSkipInitialTopScroll) {
        lastVisibleMainIndex.value = 1;
        resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: 1);
        return null;
      }
      // Nail the target before jump; gate ignores mismatched visible indices.
      lastVisibleMainIndex.value = safeIndex;
      final int generation = ++scrollGeneration.value;
      scheduleScrollToIndex(safeIndex, generation);
      return () {
        scrollGeneration.value++;
        isProgrammaticScroll.value = false;
      };
    }, <Object?>[currentIndex, imageList.length]);
    final bool useOriginalSize = zoomMode == WebtoonZoomMode.originalSize;
    final Widget pageList = ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      initialScrollIndex: initialScrollIndex,
      physics: const ClampingScrollPhysics(),
      itemCount: imageList.length,
      itemBuilder: (BuildContext context, int index) {
        final ReaderPageImageData imageData = imageList[index];
        final Widget page = ReaderImageItem(
          imageData: imageData,
          slotLogicalWidth: slotLogicalWidth,
          enableCrossfade: false,
          fit: useOriginalSize ? BoxFit.none : BoxFit.contain,
        );
        if (!useOriginalSize) {
          return page;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: viewportSize.width),
            child: page,
          ),
        );
      },
    );
    final Widget viewport = useOriginalSize
        ? pageList
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: slotLogicalWidth),
              child: pageList,
            ),
          );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: viewport,
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
