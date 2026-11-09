import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/session/reader_session_bindings.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_page_crossfade_policy.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_pages.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_viewport_prefetch_binder.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/resume_visible_sync_gate.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_image_item.dart';
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
        (AsyncValue<ReaderUiState> value) => value.asData?.value.totalPages ?? 1,
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
    final Size viewportSize = MediaQuery.sizeOf(context);
    final PageController pageController = usePageController(
      initialPage: initialPage,
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
      final int targetPage = currentIndex - 1;
      final int currentPage =
          pageController.page?.round() ?? pageController.initialPage;
      if (currentPage == targetPage) {
        resumeSyncGate.value.onVisibleIndex(currentIndex);
        return;
      }
      isProgrammaticScroll.value = true;
      resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: currentIndex);
      final int generation = ++alignGeneration.value;
      if ((currentPage - targetPage).abs() > 1) {
        pageController.jumpToPage(targetPage);
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
            targetPage,
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
        final int currentPage = pageController.hasClients
            ? (pageController.page?.round() ?? pageController.initialPage)
            : pageController.initialPage;
        if (currentPage == next - 1) {
          resumeSyncGate.value.onVisibleIndex(next);
          return;
        }
        alignToIndex(next);
      },
    );

    if (resolvedPages is! ReaderViewportPagesReady) {
      return ReaderViewportPagesFeedback(pages: resolvedPages);
    }

    final double slotLogicalWidth = readerPagedSlotLogicalWidth(
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
                onPageChanged: (int index) {
                  if (isProgrammaticScroll.value) {
                    return;
                  }
                  final int? applyIndex = resumeSyncGate.value.onVisibleIndex(
                    index + 1,
                  );
                  if (applyIndex == null) {
                    return;
                  }
                  ref
                      .read(readerViewModelProvider(viewKey).notifier)
                      .setIndex(applyIndex);
                },
                itemCount: imageList.length,
                itemBuilder: (BuildContext context, int index) {
                  final ReaderPageImageData imageData = imageList[index];
                  return ReaderImageItem(
                    comic: comic,
                    imageData: imageData,
                    slotLogicalWidth: slotLogicalWidth,
                    enableCrossfade: readerPageCrossfadeEnabled(
                      reduceMotion: MediaQuery.disableAnimationsOf(context),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        ReaderViewportPrefetchBinder(
          viewKey: viewKey,
          comicId: comicId,
          totalPages: totalPages,
          slotLogicalWidth: slotLogicalWidth,
          imageList: imageList,
        ),
      ],
    );
  }
}
