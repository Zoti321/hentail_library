import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/entities.dart' show AppSetting;
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_bottom_bar.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_content.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_route_context.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_top_bar.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/series_reader_drawer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReaderPage extends HookConsumerWidget {
  const ReaderPage({
    super.key,
    required this.comicId,
    required this.readType,
    this.seriesName,
    this.keepControlsOpen = false,
  });

  final String comicId;
  final String readType;
  final String? seriesName;
  final bool keepControlsOpen;

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
        child: const Scaffold(body: Center(child: Text('阅读参数错误：缺少 comic_id'))),
      );
    }

    final ThemeData theme = buildAppTheme(Brightness.dark);
    final AsyncValue<ReaderPageViewModel> viewAsync = ref.watch(
      readerPageViewModelProvider(
        comicId: routeContext.comicId,
        isSeriesMode: routeContext.isSeriesMode,
        seriesName: routeContext.seriesName,
      ),
    );
    final ReaderViewNotifier notifier = ref.read(
      readerViewProvider(routeContext.comicId).notifier,
    );
    final ObjectRef<bool> hasAppliedKeepControls = useRef<bool>(false);
    final bool readerWindowFullscreen = ref.watch(
      readerWindowFullscreenProvider,
    );
    final bool readerIsVertical = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readerIsVertical ?? false,
      ),
    );
    final double readerDimLevel = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readerDimLevel ?? 0.0,
      ),
    );
    final bool readerAutoPlayEnabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readerAutoPlayEnabled ?? false,
      ),
    );
    final int readerAutoPlayIntervalSeconds = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readerAutoPlayIntervalSeconds ?? 5,
      ),
    );
    final ({
      int currentIndex,
      int totalPages,
      bool isVertical,
    })? autoPlayState = ref.watch(
      readerViewProvider(routeContext.comicId).select(
        (AsyncValue<ReaderViewState> asyncState) {
          final ReaderViewState? readerState = asyncState.asData?.value;
          if (readerState == null) {
            return null;
          }
          return (
            currentIndex: readerState.currentIndex,
            totalPages: readerState.totalPages,
            isVertical: readerState.isVertical,
          );
        },
      ),
    );
    final GlobalKey<ScaffoldState> scaffoldKey = useMemoized(
      GlobalKey<ScaffoldState>.new,
      <Object?>[],
    );
    useEffect(() {
      if (!keepControlsOpen || hasAppliedKeepControls.value) {
        return null;
      }
      final ReaderPageViewModel? viewModel = viewAsync.asData?.value;
      if (viewModel == null) {
        return null;
      }
      hasAppliedKeepControls.value = true;
      if (viewModel.viewState.showControls) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setShowControls(true);
      });
      return null;
    }, <Object?>[keepControlsOpen, viewAsync, notifier]);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        notifier.setIsVertical(readerIsVertical);
      });
      return null;
    }, <Object?>[readerIsVertical, notifier, context]);
    useEffect(
      () {
        final bool canStartAutoPlay =
            readerAutoPlayEnabled &&
            !readerIsVertical &&
            autoPlayState != null &&
            autoPlayState.totalPages > 0 &&
            autoPlayState.currentIndex < autoPlayState.totalPages;
        if (!canStartAutoPlay) {
          return null;
        }
        final Duration interval = Duration(
          seconds: readerAutoPlayIntervalSeconds,
        );
        Timer? timer;
        timer = Timer.periodic(interval, (_) {
          final ReaderViewState? currentState = ref
              .read(readerViewProvider(routeContext.comicId))
              .asData
              ?.value;
          if (currentState == null) {
            return;
          }
          final bool shouldStop =
              currentState.isVertical ||
              currentState.totalPages <= 0 ||
              currentState.currentIndex >= currentState.totalPages;
          if (shouldStop) {
            timer?.cancel();
            return;
          }
          notifier.nextPage();
        });
        return () {
          timer?.cancel();
        };
      },
      <Object?>[
        readerAutoPlayEnabled,
        readerAutoPlayIntervalSeconds,
        readerIsVertical,
        autoPlayState?.currentIndex,
        autoPlayState?.totalPages,
        autoPlayState?.isVertical,
        routeContext.comicId,
        notifier,
        ref,
      ],
    );

    return Theme(
      data: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) {
            return;
          }
          await notifier.executeExitReader(
            context: context,
            routeContext: routeContext,
          );
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.colorScheme.readerBackground,
          body: viewAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace st) => Center(child: Text('$e')),
            data: (ReaderPageViewModel viewModel) {
              final ReaderViewState state = viewModel.viewState;
              final ReaderNavContextData navContext = viewModel.navContext;
              final int? preferredPageIndex = viewModel.preferredPageIndex;
              final bool canOpenComicList = navContext.items.length > 1;
              if (state.totalPages == 0) {
                return const Center(child: Text('暂无图片'));
              }
              final int initialPage = state.currentIndex - 1;
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (TapUpDetails details) {
                      if (readerIsVertical) {
                        notifier.toggleShowControls();
                        return;
                      }
                      final ReaderTapZone zone = _resolveTapZone(
                        context,
                        details.globalPosition.dx,
                      );
                      notifier.handleTapZone(zone);
                    },
                    child: ReaderContent(
                      key: ValueKey<String>(routeContext.comicId),
                      comicId: routeContext.comicId,
                      initialPage: initialPage,
                      preferredPageIndex: preferredPageIndex,
                      isVertical: readerIsVertical,
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      color: Colors.black.withAlpha(
                        (readerDimLevel * 255).round(),
                      ),
                    ),
                  ),
                  ReaderTopBar(
                    showControls: state.showControls,
                    isVertical: readerIsVertical,
                    title: state.comic.title,
                    canOpenComicList: canOpenComicList,
                    onExit: () async {
                      await notifier.executeExitReader(
                        context: context,
                        routeContext: routeContext,
                      );
                    },
                    onOpenSeriesList: () {
                      scaffoldKey.currentState?.openEndDrawer();
                    },
                    onSetHorizontalMode: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderIsVertical(false);
                    },
                    onSetVerticalMode: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderIsVertical(true);
                    },
                  ),
                  ReaderBottomBar(
                    showControls: state.showControls,
                    currentIndex: state.currentIndex,
                    totalPages: state.totalPages,
                    readerAutoPlayEnabled: readerAutoPlayEnabled,
                    readerAutoPlayIntervalSeconds:
                        readerAutoPlayIntervalSeconds,
                    readerDimLevel: readerDimLevel,
                    readerWindowFullscreen: readerWindowFullscreen,
                    onPrevPage: notifier.prevPage,
                    onNextPage: notifier.nextPage,
                    onSetIndex: notifier.setIndex,
                    onReaderAutoPlayEnabledChanged: (bool value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderAutoPlayEnabled(value);
                    },
                    onReaderAutoPlayIntervalSecondsChanged: (int value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderAutoPlayIntervalSeconds(value);
                    },
                    onReaderDimLevelChanged: (double value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderDimLevel(value);
                    },
                    onToggleFullscreen: () async {
                      await ref
                          .read(readerWindowFullscreenProvider.notifier)
                          .setFullscreen(!readerWindowFullscreen);
                    },
                  ),
                ],
              );
            },
          ),
          endDrawer: SeriesReaderDrawer(
            navContext:
                viewAsync.asData?.value.navContext ??
                ReaderNavContextData(
                  items: const <ReaderComicListItem>[],
                  currentIndex: -1,
                  preferredPageIndex: null,
                ),
            comicId: routeContext.comicId,
            onSelectComic: (String targetComicId) async {
              scaffoldKey.currentState?.closeEndDrawer();
              await notifier.executeSelectComic(
                context: context,
                routeContext: routeContext,
                targetComicId: targetComicId,
              );
            },
          ),
        ),
      ),
    );
  }

  ReaderTapZone _resolveTapZone(BuildContext context, double globalX) {
    final double width = MediaQuery.sizeOf(context).width;
    if (globalX < width * 0.3) {
      return ReaderTapZone.left;
    }
    if (globalX > width * 0.7) {
      return ReaderTapZone.right;
    }
    return ReaderTapZone.center;
  }
}
