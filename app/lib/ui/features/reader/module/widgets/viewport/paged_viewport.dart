import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_prefetch_hook.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/resume_visible_sync_gate.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
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
  });

  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;
  final int initialPage;
  final int? preferredPageIndex;
  final Future<void> Function()? onRequestNextPage;

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
    final int totalPages = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> value) => value.asData?.value.totalPages ?? 1,
      ),
    );
    final images = ref
        .watch(comicImagesProvider(comicId: comicId))
        .asData
        ?.value;
    final List<ReaderPageImageData> imageList =
        images ?? const <ReaderPageImageData>[];
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

    useReaderPrefetchWindow(
      ref: ref,
      context: context,
      comicId: comicId,
      centerPageOneBased: currentIndex,
      totalPages: totalPages,
      slotLogicalWidth: readerPagedSlotLogicalWidth(viewportSize.width),
      imageList: imageList,
    );

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
      if (!pageController.hasClients || imageList.isEmpty) {
        return null;
      }
      final int targetPage = currentIndex - 1;
      final int currentPage =
          pageController.page?.round() ?? pageController.initialPage;
      if (currentPage == targetPage) {
        // Already on resume page — release gate without waiting for onPageChanged.
        resumeSyncGate.value.onVisibleIndex(currentIndex);
        return null;
      }
      isProgrammaticScroll.value = true;
      resumeSyncGate.value.beginProgrammaticAlign(targetOneBased: currentIndex);
      final int generation = ++alignGeneration.value;
      // Large resume deltas: jump to avoid scrubbing intermediate onPageChanged.
      if ((currentPage - targetPage).abs() > 1) {
        pageController.jumpToPage(targetPage);
        resumeSyncGate.value.onVisibleIndex(currentIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || generation != alignGeneration.value) {
            return;
          }
          isProgrammaticScroll.value = false;
        });
        return () {
          alignGeneration.value++;
        };
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
      return () {
        alignGeneration.value++;
      };
    }, <Object?>[currentIndex, pageController, imageList.length]);

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
            final ReaderController notifier = ref.read(
              readerControllerProvider(viewKey).notifier,
            );
            if (dy > 0) {
              if (onRequestNextPage != null) {
                unawaited(onRequestNextPage!());
              } else {
                notifier.nextPage();
              }
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
              final int? applyIndex = resumeSyncGate.value.onVisibleIndex(
                index + 1,
              );
              if (applyIndex == null) {
                return;
              }
              ref
                  .read(readerControllerProvider(viewKey).notifier)
                  .setIndex(applyIndex);
            },
            itemCount: imageList.length,
            itemBuilder: (BuildContext context, int index) {
              final ReaderPageImageData imageData = imageList[index];
              final double slotLogicalWidth = readerPagedSlotLogicalWidth(
                MediaQuery.sizeOf(context).width,
              );
              return ReaderImageItem(
                imageData: imageData,
                slotLogicalWidth: slotLogicalWidth,
                enableCrossfade: true,
              );
            },
          ),
        ),
      ),
    );
  }
}
