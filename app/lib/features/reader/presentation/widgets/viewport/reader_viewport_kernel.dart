import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/resume_visible_sync_gate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 页（1-based）→ PageView item 索引。
typedef ReaderViewportItemIndexForPage = int Function(int pageOneBased);

/// PageView item 索引 → 该 item 的首个页（1-based）。
typedef ReaderViewportPageForItemIndex = int Function(int itemIndex);

typedef ReaderViewportItemBuilder = Widget Function(
  BuildContext context,
  int itemIndex,
  ReaderComicRef comic,
  List<ReaderPageImageData> imageList,
  double slotLogicalWidth,
);

/// 单页 / 双页视口共用的翻页 kernel。
///
/// 只承载与「索引 ↔ 页」语义无关的部分：PageController、resume gate、偏好页
/// 对齐、滚轮翻页、prefetch 槽位与可见页回写。拼页差异由
/// [itemIndexForPage] / [pageForItemIndex] / [itemBuilder] 注入。
class ReaderPagedViewportKernel extends HookConsumerWidget {
  const ReaderPagedViewportKernel({
    super.key,
    required this.viewKey,
    required this.comicId,
    required this.comic,
    required this.totalPages,
    required this.imageList,
    required this.initialPage,
    required this.initialItemIndex,
    required this.preferredPageIndex,
    required this.itemCount,
    required this.itemIndexForPage,
    required this.pageForItemIndex,
    required this.slotLogicalWidth,
    required this.itemBuilder,
    required this.prefetchBinder,
    this.fallback,
    this.onRequestNextPage,
    this.onRequestPrevPage,
  });

  final ReaderViewModelKey viewKey;
  final String comicId;
  final ReaderComicRef comic;
  final int totalPages;
  final List<ReaderPageImageData> imageList;

  /// 打开时的页（0-based），用于首次程序化对齐。
  final int initialPage;
  final int initialItemIndex;
  final int? preferredPageIndex;
  final int itemCount;
  final ReaderViewportItemIndexForPage itemIndexForPage;
  final ReaderViewportPageForItemIndex pageForItemIndex;
  final double slotLogicalWidth;
  final ReaderViewportItemBuilder itemBuilder;
  final Widget prefetchBinder;

  /// 非 null 时代替 [PageView] 渲染（页数据未就绪 / 出错）。
  final Widget? fallback;
  final Future<void> Function()? onRequestNextPage;
  final Future<void> Function()? onRequestPrevPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageController pageController = usePageController(
      initialPage: initialItemIndex,
    );
    final ObjectRef<bool> hasAppliedPreferredPage = useRef<bool>(false);
    final ObjectRef<bool> isProgrammaticScroll = useRef<bool>(false);
    final ObjectRef<int> alignGeneration = useRef<int>(0);
    final ObjectRef<ResumeVisibleSyncGate> resumeSyncGate =
        useRef<ResumeVisibleSyncGate>(ResumeVisibleSyncGate());
    final ObjectRef<DateTime?> lastWheelAt = useRef<DateTime?>(null);
    const int wheelThrottleMs = 200;

    useEffect(() {
      hasAppliedPreferredPage.value = false;
      resumeSyncGate.value = ResumeVisibleSyncGate();
      resumeSyncGate.value.beginProgrammaticAlign(
        targetOneBased: initialPage + 1,
      );
      return null;
    }, <Object?>[comicId, preferredPageIndex]);
    useEffect(() {
      if (imageList.isEmpty) {
        return null;
      }
      final int currentIndex =
          ref
              .read(readerViewModelProvider(viewKey))
              .asData
              ?.value
              .currentIndex ??
          1;
      // itemCount 0→N can reset PageView; hold sync until resume target shows.
      resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: currentIndex);
      return null;
    }, <Object?>[imageList.length]);
    useEffect(() {
      final int? preferred = preferredPageIndex;
      if (preferred == null || hasAppliedPreferredPage.value) {
        return null;
      }
      final int safeTotalPages = totalPages > 0 ? totalPages : 1;
      final int safeIndex = preferred.clamp(1, safeTotalPages);
      hasAppliedPreferredPage.value = true;
      final int currentIndex =
          ref
              .read(readerViewModelProvider(viewKey))
              .asData
              ?.value
              .currentIndex ??
          1;
      if (currentIndex != safeIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          ref
              .read(readerViewModelProvider(viewKey).notifier)
              .setIndex(safeIndex);
        });
      }
      return null;
    }, <Object?>[comicId, preferredPageIndex, totalPages]);

    void alignToIndex(int currentIndex) {
      if (!pageController.hasClients || imageList.isEmpty) {
        return;
      }
      final int targetItem = itemIndexForPage(currentIndex);
      final int currentItem =
          pageController.page?.round() ?? pageController.initialPage;
      if (currentItem == targetItem) {
        resumeSyncGate.value.onVisibleIndex(currentIndex);
        return;
      }
      isProgrammaticScroll.value = true;
      resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: currentIndex);
      final int generation = ++alignGeneration.value;
      if ((currentItem - targetItem).abs() > 1) {
        pageController.jumpToPage(targetItem);
        resumeSyncGate.value.onVisibleIndex(currentIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || generation != alignGeneration.value) {
            return;
          }
          isProgrammaticScroll.value = false;
        });
        return;
      }
      pageController
          .animateToPage(
            targetItem,
            duration: kReaderPageTurnAnimationDuration,
            curve: Curves.easeInOut,
          )
          .whenComplete(() {
            if (!context.mounted || generation != alignGeneration.value) {
              return;
            }
            resumeSyncGate.value.onVisibleIndex(currentIndex);
            isProgrammaticScroll.value = false;
          });
    }

    ref.listen<int>(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> value) =>
            value.asData?.value.currentIndex ?? 1,
      ),
      (int? previous, int next) {
        final int targetItem = itemIndexForPage(next);
        final int? currentItem = pageController.hasClients
            ? (pageController.page?.round() ?? pageController.initialPage)
            : null;
        if (currentItem == targetItem) {
          resumeSyncGate.value.onVisibleIndex(next);
          return;
        }
        alignToIndex(next);
      },
    );

    final Widget? rejected = fallback;
    if (rejected != null) {
      return rejected;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width,
            ),
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
                final ReaderViewModel notifier = ref.read(
                  readerViewModelProvider(viewKey).notifier,
                );
                if (dy > 0) {
                  if (onRequestNextPage != null) {
                    unawaited(onRequestNextPage!());
                  } else {
                    notifier.nextPage();
                  }
                } else {
                  if (onRequestPrevPage != null) {
                    unawaited(onRequestPrevPage!());
                  } else {
                    notifier.prevPage();
                  }
                }
              },
              child: PageView.builder(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int itemIndex) {
                  if (isProgrammaticScroll.value) {
                    return;
                  }
                  final int? applyIndex = resumeSyncGate.value.onVisibleIndex(
                    pageForItemIndex(itemIndex),
                  );
                  if (applyIndex == null) {
                    return;
                  }
                  ref
                      .read(readerViewModelProvider(viewKey).notifier)
                      .setIndex(applyIndex);
                },
                itemCount: itemCount,
                itemBuilder: (BuildContext context, int itemIndex) =>
                    itemBuilder(
                      context,
                      itemIndex,
                      comic,
                      imageList,
                      slotLogicalWidth,
                    ),
              ),
            ),
          ),
        ),
        prefetchBinder,
      ],
    );
  }
}
