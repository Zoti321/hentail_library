import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_page_crossfade_policy.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_prefetch_hook.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_pages.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/resume_visible_sync_gate.dart';

import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/spread_navigation.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/session/reader_session_bindings.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DualPageViewport extends HookConsumerWidget {
  const DualPageViewport({
    super.key,
    required this.comicId,
    required this.incognito,
    this.startFromFirstPage = false,
    required this.readingMode,
    required this.initialPage,
    required this.preferredPageIndex,
    this.onRequestNextPage,
    this.onRequestPrevPage,
  });

  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;
  final ReadingMode readingMode;
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
        (AsyncValue<ReaderUiState> value) => value.asData?.value.totalPages ?? 1,
      ),
    );
    final ReadingMode activeMode = ref.watch(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> value) =>
            value.asData?.value.readingMode ?? readingMode,
      ),
    );
    final Comic? comic = ref.watch(
      readerViewModelProvider(viewKey)
          .select((AsyncValue<ReaderUiState> value) => value.asData?.value.comic),
    );
    if (comic == null) {
      return const SizedBox.expand();
    }
    final ReaderViewportPages resolvedPages = resolveReaderViewportPages(
      ref.watch(comicImagesProvider(comicId: comicId)),
    );
    final List<ReaderPageImageData> imageList = switch (resolvedPages) {
      ReaderViewportPagesReady(:final List<ReaderPageImageData> pages) => pages,
      _ => const <ReaderPageImageData>[],
    };
    final int safeTotalPages = totalPages > 0 ? totalPages : 1;
    final int spreadCount = SpreadNavigation.totalSpreads(
      mode: activeMode,
      totalPages: safeTotalPages,
    );
    final int initialSpread = SpreadNavigation.spreadIndexForPage(
      mode: activeMode,
      totalPages: safeTotalPages,
      pageIndex: initialPage + 1,
    );
    final Size viewportSize = MediaQuery.sizeOf(context);
    final PageController pageController = usePageController(
      initialPage: initialSpread,
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
      resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: currentIndex);
      return null;
    }, <Object?>[imageList.length]);
    useEffect(() {
      final int? preferred = preferredPageIndex;
      if (preferred == null || hasAppliedPreferredPage.value) {
        return null;
      }
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
      final int currentSpread = SpreadNavigation.spreadIndexForPage(
        mode: activeMode,
        totalPages: safeTotalPages,
        pageIndex: currentIndex,
      );
      if (pageController.page?.round() == currentSpread) {
        resumeSyncGate.value.onVisibleIndex(currentIndex);
        return;
      }
      isProgrammaticScroll.value = true;
      resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: currentIndex);
      final int generation = ++alignGeneration.value;
      final int? currentPage = pageController.page?.round();
      if (currentPage != null && (currentPage - currentSpread).abs() > 1) {
        pageController.jumpToPage(currentSpread);
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
            currentSpread,
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
        final int currentSpread = SpreadNavigation.spreadIndexForPage(
          mode: activeMode,
          totalPages: safeTotalPages,
          pageIndex: next,
        );
        final int? page = pageController.hasClients
            ? pageController.page?.round()
            : null;
        if (page == currentSpread) {
          resumeSyncGate.value.onVisibleIndex(next);
          return;
        }
        alignToIndex(next);
      },
    );

    if (resolvedPages is! ReaderViewportPagesReady) {
      return ReaderViewportPagesFeedback(pages: resolvedPages);
    }

    final double slotLogicalWidth = readerDualPageSlotLogicalWidth(
      viewportSize.width,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
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
                final ReaderViewModel controller = ref.read(
                  readerViewModelProvider(viewKey).notifier,
                );
                if (dy > 0) {
                  if (onRequestNextPage != null) {
                    unawaited(onRequestNextPage!());
                  } else {
                    controller.nextPage();
                  }
                } else {
                  if (onRequestPrevPage != null) {
                    unawaited(onRequestPrevPage!());
                  } else {
                    controller.prevPage();
                  }
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
                  final int primaryPage = SpreadNavigation.primaryPageForSpread(
                    mode: activeMode,
                    totalPages: safeTotalPages,
                    spreadIndex: spreadIndex,
                  );
                  final int? applyIndex = resumeSyncGate.value.onVisibleIndex(
                    primaryPage,
                  );
                  if (applyIndex == null) {
                    return;
                  }
                  ref
                      .read(readerViewModelProvider(viewKey).notifier)
                      .setIndex(applyIndex);
                },
                itemCount: spreadCount,
                itemBuilder: (BuildContext context, int spreadIndex) {
                  final List<int> pages = SpreadNavigation.pagesInSpread(
                    mode: activeMode,
                    totalPages: safeTotalPages,
                    spreadIndex: spreadIndex,
                  );
                  return _DualSpreadPage(
                    comic: comic,
                    pages: pages,
                    imageList: imageList,
                  );
                },
              ),
            ),
          ),
        ),
        _DualPagePrefetchBinder(
          viewKey: viewKey,
          comicId: comicId,
          totalPages: safeTotalPages,
          slotLogicalWidth: slotLogicalWidth,
          imageList: imageList,
          readingMode: activeMode,
        ),
      ],
    );
  }
}

class _DualPagePrefetchBinder extends HookConsumerWidget {
  const _DualPagePrefetchBinder({
    required this.viewKey,
    required this.comicId,
    required this.totalPages,
    required this.slotLogicalWidth,
    required this.imageList,
    required this.readingMode,
  });

  final ReaderViewModelKey viewKey;
  final String comicId;
  final int totalPages;
  final double slotLogicalWidth;
  final List<ReaderPageImageData> imageList;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> value) =>
            value.asData?.value.currentIndex ?? 1,
      ),
    );
    final int currentSpread = SpreadNavigation.spreadIndexForPage(
      mode: readingMode,
      totalPages: totalPages,
      pageIndex: currentIndex,
    );
    final List<int> spreadPages = SpreadNavigation.pagesInSpread(
      mode: readingMode,
      totalPages: totalPages,
      spreadIndex: currentSpread,
    );
    useReaderPrefetchWindow(
      ref: ref,
      context: context,
      comicId: comicId,
      centerPageOneBased: currentIndex,
      totalPages: totalPages,
      slotLogicalWidth: slotLogicalWidth,
      imageList: imageList,
      extraPageIndexesOneBased: spreadPages,
    );
    return const SizedBox.shrink();
  }
}

class _DualSpreadPage extends StatelessWidget {
  const _DualSpreadPage({
    required this.comic,
    required this.pages,
    required this.imageList,
  });

  final Comic comic;
  final List<int> pages;
  final List<ReaderPageImageData> imageList;

  @override
  Widget build(BuildContext context) {
    final double slotLogicalWidth = readerDualPageSlotLogicalWidth(
      MediaQuery.sizeOf(context).width,
    );
    final bool enableCrossfade = readerPageCrossfadeEnabled(
      reduceMotion: MediaQuery.disableAnimationsOf(context),
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
      return Row(
        children: <Widget>[
          Expanded(
            child: ReaderImageItem(
              comic: comic,
              imageData: imageData,
              slotLogicalWidth: slotLogicalWidth,
              alignment: Alignment.centerRight,
              enableCrossfade: enableCrossfade,
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
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
                  comic: comic,
                  imageData: leftImage,
                  slotLogicalWidth: slotLogicalWidth,
                  alignment: Alignment.centerRight,
                  enableCrossfade: enableCrossfade,
                ),
        ),
        Expanded(
          child: rightImage == null
              ? const SizedBox.shrink()
              : ReaderImageItem(
                  comic: comic,
                  imageData: rightImage,
                  slotLogicalWidth: slotLogicalWidth,
                  alignment: Alignment.centerLeft,
                  enableCrossfade: enableCrossfade,
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
