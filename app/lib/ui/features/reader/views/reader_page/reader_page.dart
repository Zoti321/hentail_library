import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/interaction/app_motion.dart';
import 'package:hentai_library/ui/core/interaction/reader_input.dart';
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
    this.keepControlsOpen = false,
    this.incognito = false,
    this.startFromFirstPage = false,
  });

  final String comicId;
  final bool keepControlsOpen;
  final bool incognito;
  final bool startFromFirstPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderRouteContext routeContext = ReaderRouteContext.normalize(
      comicId: comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
    final ReaderControllerKey viewKey = readerControllerKey(
      routeContext.comicId,
      incognito: routeContext.incognito,
      startFromFirstPage: routeContext.startFromFirstPage,
    );

    if (routeContext.comicId.isEmpty) {
      return Theme(
        data: buildAppTheme(Brightness.dark),
        child: Scaffold(
          body: Center(child: Text(context.l10n.readerInvalidParams)),
        ),
      );
    }

    final ThemeData theme = buildAppTheme(Brightness.dark);
    final AsyncValue<ReaderPageViewModel> viewAsync = ref.watch(
      readerPageViewModelProvider(
        comicId: routeContext.comicId,
        incognito: routeContext.incognito,
        startFromFirstPage: routeContext.startFromFirstPage,
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
                incognito: routeContext.incognito,
                initialPageIndex: loadedViewModel.viewState.currentIndex,
              ),
        );
        return null;
      },
      <Object?>[
        routeContext.comicId,
        routeContext.incognito,
        routeContext.startFromFirstPage,
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
    final bool readerAutoPlayEnabled = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> asyncState) =>
            asyncState.asData?.value.autoPlayEnabled ?? false,
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
    final FocusNode readerFocusNode = useFocusNode();
    final bool reduceMotion = reduceMotionOf(context);
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
    useEffect(
      () {
        final bool canStartAutoPlay =
            readerAutoPlayAllowed(
              userEnabled: readerAutoPlayEnabled,
              reduceMotion: reduceMotion,
            ) &&
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
        autoPlayState?.currentIndex,
        autoPlayState?.totalPages,
        autoPlayState?.readingMode,
        routeContext.comicId,
        controller,
        ref,
        reduceMotion,
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
        showInfoToast(context, context.l10n.readerSeriesAdvancePrompt);
      });
      return null;
    }, <Object?>[seriesAdvancePromptPending, context]);

    void dispatchReaderKeyboard(LogicalKeyboardKey key) {
      final bool showControls =
          viewAsync.asData?.value.viewState.showControls ?? false;
      final ReaderKeyboardCommand? command = readerKeyboardCommandFor(
        key,
        showControls: showControls,
      );
      if (command == null) {
        return;
      }
      switch (command) {
        case ReaderKeyboardCommand.prevPage:
          controller.prevPage();
        case ReaderKeyboardCommand.nextPage:
          final ReaderPageViewModel? viewModel = viewAsync.asData?.value;
          unawaited(
            controller.requestNextPage(
              navContext: viewModel != null && viewModel.hasSeriesContext
                  ? viewModel.navContext
                  : null,
              session: routeContext.session,
              router: GoRouter.of(context),
            ),
          );
        case ReaderKeyboardCommand.hideControls:
          controller.setShowControls(false);
        case ReaderKeyboardCommand.exit:
          unawaited(
            controller.executeExitReader(
              context: context,
              routeContext: routeContext,
            ),
          );
      }
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            dispatchReaderKeyboard(LogicalKeyboardKey.arrowLeft),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            dispatchReaderKeyboard(LogicalKeyboardKey.arrowRight),
        const SingleActivator(LogicalKeyboardKey.space): () =>
            dispatchReaderKeyboard(LogicalKeyboardKey.space),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            dispatchReaderKeyboard(LogicalKeyboardKey.escape),
      },
      child: Focus(
        focusNode: readerFocusNode,
        autofocus: true,
        child: Theme(
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
                    return Center(child: Text(context.l10n.readerNoImages));
                  }
                  final int initialPage = state.currentIndex - 1;
                  final ReadingMode activeReadingMode = state.readingMode;
                  final ReaderNavContextData? seriesNavContext =
                      viewModel.hasSeriesContext ? viewModel.navContext : null;
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
                          readerFocusNode.requestFocus();
                          if (activeReadingMode.isWebtoon) {
                            controller.toggleShowControls();
                            return;
                          }
                          final ReaderTapZone zone = resolveReaderTapZone(
                            globalX: details.globalPosition.dx,
                            width: MediaQuery.sizeOf(context).width,
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
                          startFromFirstPage: routeContext.startFromFirstPage,
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
                        seriesId: viewModel.seriesId,
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
                        showAutoPlayControls:
                            activeReadingMode.supportsAutoPlay,
                        onPrevPage: controller.prevPage,
                        onNextPage: requestNextPage,
                        onSetIndex: controller.setIndex,
                        onReaderAutoPlayEnabledChanged: (bool value) {
                          controller.setAutoPlayEnabled(value);
                        },
                        showSeriesComicNav: seriesNavContext != null,
                        onPrevSeriesComic:
                            seriesNavContext?.previousItem != null
                            ? () async {
                                final String targetComicId =
                                    seriesNavContext!.previousItem!.comicId;
                                await ref
                                    .read(
                                      readerSeriesNavigationProvider.notifier,
                                    )
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
                                    .read(
                                      readerSeriesNavigationProvider.notifier,
                                    )
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
        ),
      ),
    );
  }
}
