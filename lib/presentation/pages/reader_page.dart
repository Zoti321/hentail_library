import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolved series context for reader navigation (prev/next + drawer).
class SeriesReaderNavData {
  const SeriesReaderNavData({
    required this.seriesName,
    required this.sortedItems,
    required this.currentIndex,
  });
  final String seriesName;
  final List<SeriesItem> sortedItems;
  final int currentIndex;
}

enum ReaderReadType {
  comic,
  series,
}

class ReaderRouteContext {
  const ReaderRouteContext({
    required this.comicId,
    required this.readType,
    this.seriesName,
  });

  final String comicId;
  final ReaderReadType readType;
  final String? seriesName;

  bool get isSeriesMode => readType == ReaderReadType.series;

  static ReaderRouteContext normalize({
    required String comicId,
    required String readType,
    String? seriesName,
  }) {
    final ReaderReadType parsedType = readType == 'series'
        ? ReaderReadType.series
        : ReaderReadType.comic;
    final String normalizedComicId = comicId.trim();
    final String? normalizedSeriesName =
        seriesName != null && seriesName.isNotEmpty ? seriesName : null;
    final bool isValidSeries =
        parsedType == ReaderReadType.series && normalizedSeriesName != null;
    return ReaderRouteContext(
      comicId: normalizedComicId,
      readType: isValidSeries ? ReaderReadType.series : ReaderReadType.comic,
      seriesName: isValidSeries ? normalizedSeriesName : null,
    );
  }
}

SeriesReaderNavData? buildSeriesReaderNavData(Series? series, String comicId) {
  if (series == null || !series.containsComic(comicId)) {
    return null;
  }
  final List<SeriesItem> sorted = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  final int idx = sorted.indexWhere((SeriesItem e) => e.comicId == comicId);
  if (idx < 0) {
    return null;
  }
  return SeriesReaderNavData(
    seriesName: series.name,
    sortedItems: sorted,
    currentIndex: idx,
  );
}

class ReaderPage extends HookConsumerWidget {
  final String comicId;
  final String readType;
  final String? seriesName;

  const ReaderPage({
    super.key,
    required this.comicId,
    required this.readType,
    this.seriesName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderRouteContext routeContext = ReaderRouteContext.normalize(
      comicId: comicId,
      readType: readType,
      seriesName: seriesName,
    );
    if (routeContext.comicId.isEmpty) {
      return Theme(
        data: buildAppTheme(Brightness.dark),
        child: const Scaffold(
          body: Center(child: Text('阅读参数错误：缺少 comic_id')),
        ),
      );
    }
    final theme = buildAppTheme(Brightness.dark);
    final viewAsync = ref.watch(readerViewProvider(routeContext.comicId));
    final GlobalKey<ScaffoldState> scaffoldKey = useMemoized(
      GlobalKey<ScaffoldState>.new,
      <Object?>[],
    );
    final String? seriesQuery = routeContext.seriesName;
    final SeriesReaderNavData? seriesNav =
        routeContext.isSeriesMode
        ? ref
              .watch(seriesByNameForReaderProvider(seriesQuery!))
              .when(
                data: (Series? s) =>
                    buildSeriesReaderNavData(s, routeContext.comicId),
                loading: () => null,
                error: (Object _, StackTrace _) => null,
              )
        : null;

    return Theme(
      data: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          _exitReaderPage(context, ref, routeContext);
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.colorScheme.readerBackground,
          endDrawer: seriesNav != null
              ? _SeriesReaderDrawer(
                  nav: seriesNav,
                  comicId: routeContext.comicId,
                  onSelectComic: (String targetComicId) {
                    _saveProgress(
                      ref,
                      routeContext.comicId,
                      routeContext: routeContext,
                    );
                    scaffoldKey.currentState?.closeEndDrawer();
                    context.pushReplacementNamed(
                      '阅读页面',
                      queryParameters: <String, String>{
                        'read_type': 'series',
                        'comic_id': targetComicId,
                        'series_name': seriesNav.seriesName,
                      },
                    );
                  },
                )
              : null,
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
                        .read(readerViewProvider(routeContext.comicId).notifier)
                        .handleTap(details, context),
                    child: _ReaderContent(
                      comicId: routeContext.comicId,
                      initialPage: initialPage,
                    ),
                  ),
                  _TopBar(
                    comicId: routeContext.comicId,
                    seriesNav: seriesNav,
                    scaffoldKey: scaffoldKey,
                    routeContext: routeContext,
                  ),
                  _BottomBar(comicId: routeContext.comicId),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

void _saveProgress(
  WidgetRef ref,
  String comicId, {
  required ReaderRouteContext routeContext,
}) {
  final state = ref.read(readerViewProvider(comicId)).asData?.value;
  if (state == null) return;
  final comic = state.comic;
  final currentIndex = state.currentIndex;
  final DateTime now = DateTime.now();
  final String? seriesName = routeContext.isSeriesMode
      ? routeContext.seriesName
      : null;
  final entity.SeriesReadingHistory? series =
      seriesName != null && seriesName.isNotEmpty
      ? entity.SeriesReadingHistory(
          seriesName: seriesName,
          lastReadComicId: comicId,
          lastReadTime: now,
          pageIndex: currentIndex,
        )
      : null;
  ref
      .read(recordReadingProgressUseCaseProvider)
      .call(
        entity.ReadingHistory(
          comicId: comicId,
          title: comic.title,
          lastReadTime: now,
          pageIndex: currentIndex,
        ),
        series: series,
      );
}

void _exitReaderPage(
  BuildContext context,
  WidgetRef ref,
  ReaderRouteContext routeContext,
) {
  _saveProgress(ref, routeContext.comicId, routeContext: routeContext);
  final GoRouter router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  final String? seriesName = routeContext.isSeriesMode
      ? routeContext.seriesName
      : null;
  if (seriesName != null) {
    router.goNamed(
      '系列详情',
      pathParameters: <String, String>{'name': seriesName},
    );
    return;
  }
  router.go('/home');
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

    final ObjectRef<DateTime?> lastWheelAt = useRef<DateTime?>(null);
    const int wheelThrottleMs = 200;

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
                          padding: const EdgeInsets.all(24),
                          child: Icon(
                            LucideIcons.bookImage,
                            size: 24,
                            color: Theme.of(
                              context,
                            ).colorScheme.readerTextMuted,
                          ),
                        );
                },
              )
            : Listener(
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
                  onPageChanged: (int index) => ref
                      .read(readerViewProvider(comicId).notifier)
                      .setIndex(index + 1),
                  itemCount: images?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    final file = images?[index];

                    return file != null
                        ? Image.file(file, fit: BoxFit.contain)
                        : Container(
                            padding: const EdgeInsets.all(24),
                            child: Icon(
                              LucideIcons.bookImage,
                              size: 24,
                              color: Theme.of(
                                context,
                              ).colorScheme.readerTextMuted,
                            ),
                          );
                  },
                ),
              ),
      ),
    );
  }
}

class _TopBar extends HookConsumerWidget {
  const _TopBar({
    required this.comicId,
    required this.seriesNav,
    required this.scaffoldKey,
    required this.routeContext,
  });

  final String comicId;
  final SeriesReaderNavData? seriesNav;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ReaderRouteContext routeContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(readerViewProvider(comicId)).requireValue;
    final showControls = state.showControls;
    final isVertival = state.isVertical;

    final topPadding = MediaQuery.of(context).padding.top + 24;
    final SeriesReaderNavData? nav = seriesNav;

    void goToSeriesComic(int delta) {
      if (nav == null) return;
      final int next = nav.currentIndex + delta;
      if (next < 0 || next >= nav.sortedItems.length) return;
      final String targetId = nav.sortedItems[next].comicId;
      _saveProgress(ref, comicId, routeContext: routeContext);
      context.pushReplacementNamed(
        '阅读页面',
        queryParameters: <String, String>{
          'read_type': 'series',
          'comic_id': targetId,
          'series_name': nav.seriesName,
        },
      );
    }

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
                constraints: BoxConstraints(maxWidth: nav != null ? 720 : 500),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.readerPanelBackground,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(width: 1, color: cs.readerPanelBorder),
                ),
                child: Row(
                  spacing: 12,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        _exitReaderPage(context, ref, routeContext);
                      },
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        size: 16,
                        color: cs.readerTextIconPrimary,
                      ),
                    ),
                    if (nav != null) ...[
                      IconButton(
                        tooltip: '上一部',
                        onPressed: nav.currentIndex > 0
                            ? () => goToSeriesComic(-1)
                            : null,
                        icon: Icon(
                          LucideIcons.chevronsLeft,
                          size: 18,
                          color: nav.currentIndex > 0
                              ? cs.readerTextIconPrimary
                              : cs.readerTextMuted,
                        ),
                      ),
                    ],
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
                    if (nav != null) ...[
                      IconButton(
                        tooltip: '下一部',
                        onPressed: nav.currentIndex < nav.sortedItems.length - 1
                            ? () => goToSeriesComic(1)
                            : null,
                        icon: Icon(
                          LucideIcons.chevronsRight,
                          size: 18,
                          color: nav.currentIndex < nav.sortedItems.length - 1
                              ? cs.readerTextIconPrimary
                              : cs.readerTextMuted,
                        ),
                      ),
                      IconButton(
                        tooltip: '系列列表',
                        onPressed: () {
                          scaffoldKey.currentState?.openEndDrawer();
                        },
                        icon: Icon(
                          LucideIcons.list,
                          size: 18,
                          color: cs.readerTextIconPrimary,
                        ),
                      ),
                    ],
                    // 阅读模式切换按钮组
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.readerPanelSubtle,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: cs.readerPanelSubtleBorder),
                      ),
                      child: Row(
                        spacing: 2,
                        mainAxisSize: MainAxisSize.min,
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
    );
  }
}

class _SeriesReaderDrawer extends ConsumerWidget {
  const _SeriesReaderDrawer({
    required this.nav,
    required this.comicId,
    required this.onSelectComic,
  });

  final SeriesReaderNavData nav;
  final String comicId;
  final void Function(String targetComicId) onSelectComic;

  static String _titleForComic(WidgetRef ref, String id) {
    final String? title = ref
        .read(libraryPageProvider.notifier)
        .comicById(id)
        ?.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return id.length > 12 ? '${id.substring(0, 12)}…' : id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: cs.readerBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '系列：${nav.seriesName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.readerTextIconPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: cs.readerTextIconPrimary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.readerPanelBorder),
            Expanded(
              child: ListView.builder(
                itemCount: nav.sortedItems.length,
                itemBuilder: (BuildContext context, int index) {
                  final SeriesItem item = nav.sortedItems[index];
                  final bool isCurrent = item.comicId == comicId;
                  final String title = _titleForComic(ref, item.comicId);
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: cs.readerPanelSubtle,
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.readerTextIconPrimary,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    leading: SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.readerTextSecondary,
                        ),
                      ),
                    ),
                    onTap: isCurrent ? null : () => onSelectComic(item.comicId),
                  );
                },
              ),
            ),
          ],
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.floatingUiBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.readerPanelBorder, width: 1),
                ),
                child: Column(
                  spacing: 12,
                  mainAxisSize: MainAxisSize.min,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? cs.readerTextOnWhite
                    : cs.readerTextIconPrimary,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? cs.readerTextOnWhite
                      : cs.readerTextIconPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
