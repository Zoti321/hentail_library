import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/domain/entity/reading_session.dart' as entity;
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:window_manager/window_manager.dart';

class ReaderPage extends HookConsumerWidget {
  final String comicId;

  const ReaderPage({super.key, required this.comicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = buildAppTheme(Brightness.dark);
    final viewAsync = ref.watch(readerViewProvider(comicId));

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(readingSessionStartProvider.notifier)
            .setStartedAt(DateTime.now());
      });
      return null;
    }, [comicId]);

    return Theme(
      data: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _saveProgress(ref, comicId);
          Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.readerBackground,
          body: viewAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('$e')),
            data: (state) {
              if (state.totalPages == 0) {
                return const Center(child: Text('暂无图片'));
              }
              final initialPage = state.currentIndex - 1;
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => ref
                        .read(readerViewProvider(comicId).notifier)
                        .handleTap(details, context),
                    child: _ReaderContent(
                      comicId: comicId,
                      initialPage: initialPage,
                    ),
                  ),
                  _TopBar(comicId: comicId),
                  _BottomBar(comicId: comicId),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

void _saveProgress(WidgetRef ref, String comicId) {
  final state = ref.read(readerViewProvider(comicId)).asData?.value;
  if (state == null) return;
  final comic = state.comic;
  final currentIndex = state.currentIndex;

  final sessionStart = ref.read(readingSessionStartProvider);
  if (sessionStart != null) {
    final durationSeconds = DateTime.now().difference(sessionStart).inSeconds;
    if (durationSeconds > 0) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      ref
          .read(recordReadingSessionUseCaseProvider)
          .call(
            entity.ReadingSession(
              comicId: comicId,
              date: today,
              durationSeconds: durationSeconds,
            ),
          );
    }
    ref.read(readingSessionStartProvider.notifier).setStartedAt(null);
    ref.invalidate(readingStatsProvider);
  }

  ref
      .read(recordReadingProgressUseCaseProvider)
      .call(
        entity.ReadingHistory(
          comicId: comicId,
          title: comic.title,
          lastReadTime: DateTime.now(),
          pageIndex: currentIndex,
        ),
      );
}

class _ReaderContent extends HookConsumerWidget {
  const _ReaderContent({required this.comicId, required this.initialPage});

  final String comicId;
  final int initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(readerViewProvider(comicId));
    final state = stateAsync.requireValue;
    final isVertical = state.isVertical;
    final scale = isVertical ? 0.8 : 0.6;

    final ScrollController scrollController = ScrollController();

    final PageController pageController = useMemoized(
      () => PageController(initialPage: initialPage),
      [initialPage],
    );
    ref.listen<AsyncValue<ReaderViewState>>(readerViewProvider(comicId), (
      previous,
      next,
    ) {
      next.whenData((s) {
        if (pageController.hasClients) {
          final targetPage = s.currentIndex - 1;
          if (pageController.page?.round() != targetPage) {
            pageController.jumpToPage(targetPage);
          }
        }
      });
    });

    final images = ref
        .watch(comicImagesProvider(comicId: comicId))
        .asData
        ?.value;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * scale,
        ),
        child: isVertical
            ? ListView.builder(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                itemCount: images?.length ?? 0,
                itemBuilder: (context, index) {
                  final file = images?[index];

                  return file != null
                      ? Image.file(file, fit: BoxFit.contain)
                      : Container(
                          padding: const .all(24),
                          child: Icon(
                            LucideIcons.bookImage,
                            size: 24,
                            color: Theme.of(context).colorScheme.readerTextMuted,
                          ),
                        );
                },
              )
            : PageView.builder(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => ref
                    .read(readerViewProvider(comicId).notifier)
                    .setIndex(index + 1),
                itemCount: images?.length ?? 0,
                itemBuilder: (context, index) {
                  final file = images?[index];

                  return file != null
                      ? Image.file(file, fit: BoxFit.contain)
                      : Container(
                          padding: const .all(24),
                          child: Icon(
                            LucideIcons.bookImage,
                            size: 24,
                            color: Theme.of(context).colorScheme.readerTextMuted,
                          ),
                        );
                },
              ),
      ),
    );
  }
}

class _TopBar extends HookConsumerWidget {
  const _TopBar({required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(readerViewProvider(comicId)).requireValue;
    final showControls = state.showControls;
    final isVertival = state.isVertical;

    final topPadding = MediaQuery.of(context).padding.top + 24;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: showControls ? topPadding : topPadding - 20,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: showControls ? 1.0 : 0.0,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const .all(6),
                decoration: BoxDecoration(
                  color: cs.readerPanelBackground,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(width: 1, color: cs.readerPanelBorder),
                ),
                child: DragToMoveArea(
                  child: Row(
                    spacing: 12,
                    mainAxisSize: .min,
                    children: [
                      IconButton(
                        onPressed: () {
                          _saveProgress(ref, comicId);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          LucideIcons.arrowLeft,
                          size: 16,
                          color: cs.readerTextIconPrimary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          state.comic.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.readerTextIconPrimary,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 阅读模式切换按钮组
                      Container(
                        padding: const .all(4),
                        decoration: BoxDecoration(
                          color: cs.readerPanelSubtle,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: cs.readerPanelSubtleBorder),
                        ),
                        child: Row(
                          spacing: 2,
                          mainAxisSize: .min,
                          children: [
                            _ReadModeToggleBtn(
                              icon: LucideIcons.bookOpen,
                              label: "翻页",
                              isVertical: false,
                              isActive: !isVertival,
                              onTap: () {
                                ref
                                    .read(readerViewProvider(comicId).notifier)
                                    .setIsVertical(false);
                              },
                            ),
                            _ReadModeToggleBtn(
                              icon: LucideIcons.arrowUpDown,
                              label: '条漫',
                              isVertical: true,
                              isActive: isVertival,
                              onTap: () {
                                ref
                                    .read(readerViewProvider(comicId).notifier)
                                    .setIsVertical(true);
                              },
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.settings2,
                        size: 16,
                        color: cs.readerTextIconPrimary,
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends HookConsumerWidget {
  const _BottomBar({required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(readerViewProvider(comicId)).requireValue;
    final showControls = state.showControls;
    final currentIndex = state.currentIndex;
    final totalPages = state.totalPages;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: showControls ? bottomPadding : bottomPadding - 32,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: showControls ? 1.0 : 0.0,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 672),
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: cs.floatingUiBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.readerPanelBorder, width: 1),
                ),
                child: Column(
                  spacing: 12,
                  mainAxisSize: .min,
                  children: [
                    // 阅读进度 信息
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cs.readerTextSecondary,
                            ),
                          ),
                          Text(
                            '$currentIndex / $totalPages',
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cs.readerTextIconPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(readerViewProvider(comicId).notifier)
                                .prevPage();
                          },
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            color: cs.readerTextIconPrimary,
                          ),
                        ),

                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: cs.sliderActive,
                                inactiveTrackColor: cs.sliderInactive,
                                thumbColor: cs.activeButtonBg,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                  elevation: 4,
                                ),
                                overlayColor: cs.readerSliderOverlay,
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                                trackShape: const RoundedRectSliderTrackShape(),
                              ),
                              child: Slider(
                                value: currentIndex.toDouble(),
                                min: 1,
                                max: totalPages.toDouble(),
                                onChanged: (val) {
                                  ref
                                      .read(
                                        readerViewProvider(comicId).notifier,
                                      )
                                      .setIndex(val.toInt());
                                },
                              ),
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            ref
                                .read(readerViewProvider(comicId).notifier)
                                .nextPage();
                          },
                          icon: Icon(
                            LucideIcons.chevronRight,
                            color: cs.readerTextIconPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadModeToggleBtn extends HookConsumerWidget {
  const _ReadModeToggleBtn({
    required this.icon,
    required this.label,
    required this.isVertical,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isVertical;
  final bool isActive;
  final VoidFunction onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? cs.activeButtonBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            spacing: 6,
            mainAxisSize: .min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? cs.readerTextOnWhite : cs.readerTextIconPrimary,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? cs.readerTextOnWhite : cs.readerTextIconPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
