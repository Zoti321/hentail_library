import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_bottom_bar.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_content.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_top_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReaderPage extends HookConsumerWidget {
  const ReaderPage({
    super.key,
    required this.comicId,
    this.seriesId,
    this.keepControlsOpen = false,
    this.incognito = false,
  });

  final String comicId;
  final String? seriesId;
  final bool keepControlsOpen;
  final bool incognito;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderRouteContext routeContext = ReaderRouteContext.normalize(
      comicId: comicId,
      seriesId: seriesId,
      incognito: incognito,
    );
    final ReaderControllerKey viewKey = readerControllerKey(
      routeContext.comicId,
      incognito: routeContext.incognito,
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
        seriesId: routeContext.seriesId,
        incognito: routeContext.incognito,
      ),
    );
    final bool readerReady = viewAsync.hasValue;
    final ReaderPageViewModel? loadedViewModel = viewAsync.asData?.value;
    useEffect(
      () {
        if (!readerReady || loadedViewModel == null) {
          return null;
        }
        unawaited(
          ref
              .read(readSessionCoordinatorProvider)
              .beginReadSession(
                comic: loadedViewModel.viewState.comic,
                mode: routeContext.session.mode,
                seriesId: routeContext.seriesId,
                incognito: routeContext.incognito,
                initialPageIndex: loadedViewModel.viewState.currentIndex,
              ),
        );
        return null;
      },
      <Object?>[
        routeContext.comicId,
        routeContext.seriesId,
        routeContext.incognito,
        readerReady,
      ],
    );
    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
    );
    final ObjectRef<bool> hasAppliedKeepControls = useRef<bool>(false);
    final bool readerFullscreen = ref.watch(readerFullscreenControllerProvider);
    final bool seriesAdvancePromptPending = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> asyncState) =>
            asyncState.asData?.value.seriesAdvancePromptPending ?? false,
      ),
    );
    final ReadingMode globalReadingMode = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readingMode ?? kDefaultReadingMode,
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
    final ({int currentIndex, int totalPages, ReadingMode readingMode})?
    autoPlayState = ref.watch(
      readerControllerProvider(viewKey).select((
        AsyncValue<ReaderState> asyncState,
      ) {
        final ReaderState? readerState = asyncState.asData?.value;
        if (readerState == null) {
          return null;
        }
        return (
          currentIndex: readerState.currentIndex,
          totalPages: readerState.totalPages,
          readingMode: readerState.readingMode,
        );
      }),
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
        controller.setShowControls(true);
      });
      return null;
    }, <Object?>[keepControlsOpen, viewAsync, controller]);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        controller.setReadingMode(globalReadingMode);
      });
      return null;
    }, <Object?>[globalReadingMode, controller, context]);
    useEffect(
      () {
        final bool canStartAutoPlay =
            readerAutoPlayEnabled &&
            autoPlayState != null &&
            autoPlayState.readingMode.supportsAutoPlay &&
            autoPlayState.totalPages > 0 &&
            !SpreadIndex.isOnLastSpread(
              mode: autoPlayState.readingMode,
              totalPages: autoPlayState.totalPages,
              currentPageIndex: autoPlayState.currentIndex,
            );
        if (!canStartAutoPlay) {
          return null;
        }
        final Duration interval = Duration(
          seconds: readerAutoPlayIntervalSeconds,
        );
        Timer? timer;
        timer = Timer.periodic(interval, (_) {
          final ReaderState? currentState = ref
              .read(readerControllerProvider(viewKey))
              .asData
              ?.value;
          if (currentState == null) {
            return;
          }
          final bool shouldStop =
              !currentState.readingMode.supportsAutoPlay ||
              currentState.totalPages <= 0 ||
              SpreadIndex.isOnLastSpread(
                mode: currentState.readingMode,
                totalPages: currentState.totalPages,
                currentPageIndex: currentState.currentIndex,
              );
          if (shouldStop) {
            timer?.cancel();
            return;
          }
          controller.nextPage();
        });
        return () {
          timer?.cancel();
        };
      },
      <Object?>[
        readerAutoPlayEnabled,
        readerAutoPlayIntervalSeconds,
        globalReadingMode,
        autoPlayState?.currentIndex,
        autoPlayState?.totalPages,
        autoPlayState?.readingMode,
        routeContext.comicId,
        controller,
        ref,
      ],
    );
    useEffect(() {
      if (!seriesAdvancePromptPending) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        showInfoToast(context, '再次翻页将进入下一卷');
      });
      return null;
    }, <Object?>[seriesAdvancePromptPending, context]);

    return Theme(
      data: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) {
            return;
          }
          await controller.executeExitReader(
            context: context,
            routeContext: routeContext,
          );
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.colorScheme.hentai.readerBackground,
          body: viewAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace st) => Center(child: Text('$e')),
            data: (ReaderPageViewModel viewModel) {
              final ReaderState state = viewModel.viewState;
              final int? preferredPageIndex = viewModel.preferredPageIndex;
              if (state.totalPages == 0) {
                return const Center(child: Text('暂无图片'));
              }
              final int initialPage = state.currentIndex - 1;
              final ReadingMode activeReadingMode = state.readingMode;
              final ReaderNavContextData? seriesNavContext =
                  viewModel.isSeriesRead ? viewModel.navContext : null;
              Future<void> requestNextPage() => controller.requestNextPage(
                navContext: seriesNavContext,
                session: routeContext.session,
                router: GoRouter.of(context),
              );
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (TapUpDetails details) {
                      if (activeReadingMode.isWebtoon) {
                        controller.toggleShowControls();
                        return;
                      }
                      final ReaderTapZone zone = _resolveTapZone(
                        context,
                        details.globalPosition.dx,
                      );
                      controller.handleTapZone(
                        zone,
                        navContext: seriesNavContext,
                        session: routeContext.session,
                        router: GoRouter.of(context),
                      );
                    },
                    child: ReaderContent(
                      key: ValueKey<String>(routeContext.comicId),
                      comicId: routeContext.comicId,
                      incognito: routeContext.incognito,
                      initialPage: initialPage,
                      preferredPageIndex: preferredPageIndex,
                      readingMode: activeReadingMode,
                      onRequestNextPage: requestNextPage,
                    ),
                  ),
                  ReaderTopBar(
                    showControls: state.showControls,
                    title: state.comic.title,
                    readerFullscreen: readerFullscreen,
                    navContext: seriesNavContext,
                    session: routeContext.session,
                    onExit: () async {
                      await controller.executeExitReader(
                        context: context,
                        routeContext: routeContext,
                      );
                    },
                    onToggleFullscreen: controller.toggleFullscreen,
                  ),
                  ReaderBottomBar(
                    showControls: state.showControls,
                    currentIndex: state.currentIndex,
                    totalPages: state.totalPages,
                    readerAutoPlayEnabled: readerAutoPlayEnabled,
                    showAutoPlayControls: activeReadingMode.supportsAutoPlay,
                    onPrevPage: controller.prevPage,
                    onNextPage: requestNextPage,
                    onSetIndex: controller.setIndex,
                    onReaderAutoPlayEnabledChanged: (bool value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderAutoPlayEnabled(value);
                    },
                    onPrevSeriesComic: seriesNavContext?.previousItem != null
                        ? () async {
                            final String targetComicId =
                                seriesNavContext!.previousItem!.comicId;
                            await ref
                                .read(readerSeriesNavigationProvider.notifier)
                                .switchComic(
                                  router: GoRouter.of(context),
                                  currentSession: routeContext.session,
                                  targetComicId: targetComicId,
                                );
                          }
                        : null,
                    onNextSeriesComic: seriesNavContext?.nextItem != null
                        ? () async {
                            final String targetComicId =
                                seriesNavContext!.nextItem!.comicId;
                            await ref
                                .read(readerSeriesNavigationProvider.notifier)
                                .switchComic(
                                  router: GoRouter.of(context),
                                  currentSession: routeContext.session,
                                  targetComicId: targetComicId,
                                );
                          }
                        : null,
                  ),
                ],
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
