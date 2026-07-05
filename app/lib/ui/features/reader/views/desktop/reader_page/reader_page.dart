import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/view_models/reader_window_fullscreen.dart';
import 'package:hentai_library/ui/features/shell/state/reading_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_bottom_bar.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_content.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_top_bar.dart';
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
              .read(readingAggregateProvider.notifier)
              .beginSession(
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
    final bool readerWindowFullscreen = ref.watch(
      readerWindowFullscreenProvider,
    );
    final ReadingMode globalReadingMode = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readingMode ?? kDefaultReadingMode,
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
            autoPlayState.currentIndex < autoPlayState.totalPages;
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
              currentState.currentIndex >= currentState.totalPages;
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
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (TapUpDetails details) {
                      if (activeReadingMode.isContinuousVertical) {
                        controller.toggleShowControls();
                        return;
                      }
                      final ReaderTapZone zone = _resolveTapZone(
                        context,
                        details.globalPosition.dx,
                      );
                      controller.handleTapZone(zone);
                    },
                    child: ReaderContent(
                      key: ValueKey<String>(routeContext.comicId),
                      comicId: routeContext.comicId,
                      incognito: routeContext.incognito,
                      initialPage: initialPage,
                      preferredPageIndex: preferredPageIndex,
                      readingMode: activeReadingMode,
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
                    readingMode: activeReadingMode,
                    title: state.comic.title,
                    navContext: viewModel.isSeriesRead
                        ? viewModel.navContext
                        : null,
                    session: routeContext.session,
                    onExit: () async {
                      await controller.executeExitReader(
                        context: context,
                        routeContext: routeContext,
                      );
                    },
                    onReadingModeChanged: (ReadingMode mode) {
                      ref.read(settingsProvider.notifier).setReadingMode(mode);
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
                    onPrevPage: controller.prevPage,
                    onNextPage: controller.nextPage,
                    onSetIndex: controller.setIndex,
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
