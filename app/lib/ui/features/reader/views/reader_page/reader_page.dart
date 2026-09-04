import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/core/interaction/app_motion.dart';
import 'package:hentai_library/ui/core/interaction/reader_input.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_bottom_bar.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_content.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_top_bar.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Stable open-session fields for [ReaderPage] shell (excludes index/chrome/mode).
typedef ReaderPageShellData = ({
  Comic comic,
  int totalPages,
  ReadSessionContextData sessionContext,
});

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

    // Shell watch: comic + totalPages only — page turns must not rebuild chrome tree.
    final AsyncValue<({Comic comic, int totalPages})> viewShellAsync = ref.watch(
      readerControllerProvider(viewKey).select((
        AsyncValue<ReaderState> asyncState,
      ) {
        if (asyncState.hasError) {
          return AsyncError<({Comic comic, int totalPages})>(
            asyncState.error!,
            asyncState.stackTrace!,
          );
        }
        final ReaderState? state = asyncState.asData?.value;
        if (state == null) {
          return const AsyncLoading<({Comic comic, int totalPages})>();
        }
        return AsyncData<({Comic comic, int totalPages})>((
          comic: state.comic,
          totalPages: state.totalPages,
        ));
      }),
    );
    final AsyncValue<ReadSessionContextData> sessionAsync = ref.watch(
      readSessionContextForReaderProvider(
        comicId: routeContext.comicId,
        incognito: routeContext.incognito,
        startFromFirstPage: routeContext.startFromFirstPage,
      ),
    );
    final AsyncValue<ReaderPageShellData> shellAsync = _combineReaderShell(
      viewShellAsync,
      sessionAsync,
    );

    final bool readerReady = shellAsync.hasValue;
    final ReaderPageShellData? loadedShell = shellAsync.asData?.value;
    final ObjectRef<int?> frozenOpenIndex = useRef<int?>(null);
    final ObjectRef<int?> frozenInitialPage = useRef<int?>(null);
    final ObjectRef<String?> frozenSessionKey = useRef<String?>(null);
    final String sessionKey =
        '${routeContext.comicId}|${routeContext.incognito}|${routeContext.startFromFirstPage}';
    if (frozenSessionKey.value != sessionKey) {
      frozenSessionKey.value = sessionKey;
      frozenOpenIndex.value = null;
      frozenInitialPage.value = null;
    }

    // Freeze resume index synchronously on first ready frame (before content builds).
    if (loadedShell != null && frozenInitialPage.value == null) {
      final int openIndex =
          ref.read(readerControllerProvider(viewKey)).asData?.value.currentIndex ??
          1;
      frozenOpenIndex.value = openIndex;
      frozenInitialPage.value = openIndex - 1;
    }

    useEffect(
      () {
        if (!readerReady || loadedShell == null || frozenOpenIndex.value == null) {
          return null;
        }
        unawaited(
          ref
              .read(readSessionCoordinatorProvider)
              .beginReadSession(
                comic: loadedShell.comic,
                incognito: routeContext.incognito,
                initialPageIndex: frozenOpenIndex.value!,
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
    final GlobalKey<ScaffoldState> scaffoldKey = useMemoized(
      GlobalKey<ScaffoldState>.new,
      <Object?>[],
    );
    final FocusNode readerFocusNode = useFocusNode();

    useEffect(() {
      if (!keepControlsOpen || hasAppliedKeepControls.value) {
        return null;
      }
      if (!readerReady) {
        return null;
      }
      hasAppliedKeepControls.value = true;
      final bool showControls =
          ref.read(readerControllerProvider(viewKey)).asData?.value.showControls ??
          false;
      if (showControls) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setShowControls(true);
      });
      return null;
    }, <Object?>[keepControlsOpen, readerReady, controller]);

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
          ref.read(readerControllerProvider(viewKey)).asData?.value.showControls ??
          false;
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
          final ReaderPageShellData? shell = shellAsync.asData?.value;
          unawaited(
            controller.requestNextPage(
              navContext: shell != null && shell.sessionContext.hasSeriesContext
                  ? shell.sessionContext.navContext
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
              body: shellAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Center(child: Text('$e')),
                data: (ReaderPageShellData shell) {
                  if (shell.totalPages == 0) {
                    return Center(child: Text(context.l10n.readerNoImages));
                  }
                  final int initialPage = frozenInitialPage.value!;
                  final ReaderNavContextData? seriesNavContext =
                      shell.sessionContext.hasSeriesContext
                      ? shell.sessionContext.navContext
                      : null;
                  return Stack(
                    children: <Widget>[
                      _ReaderContentSlot(
                        viewKey: viewKey,
                        routeContext: routeContext,
                        readerFocusNode: readerFocusNode,
                        initialPage: initialPage,
                        preferredPageIndex: shell.sessionContext.preferredPageIndex,
                        seriesNavContext: seriesNavContext,
                      ),
                      _ReaderTopBarSlot(
                        viewKey: viewKey,
                        title: shell.comic.title,
                        readerFullscreen: readerFullscreen,
                        navContext: seriesNavContext,
                        session: routeContext.session,
                        seriesId: shell.sessionContext.seriesId,
                        routeContext: routeContext,
                      ),
                      _ReaderBottomBarSlot(
                        viewKey: viewKey,
                        totalPages: shell.totalPages,
                        seriesNavContext: seriesNavContext,
                        routeContext: routeContext,
                      ),
                      _ReaderAutoPlayBinder(
                        viewKey: viewKey,
                        routeContext: routeContext,
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

AsyncValue<ReaderPageShellData> _combineReaderShell(
  AsyncValue<({Comic comic, int totalPages})> viewShell,
  AsyncValue<ReadSessionContextData> session,
) {
  if (viewShell.hasError) {
    return AsyncError(viewShell.error!, viewShell.stackTrace!);
  }
  if (session.hasError) {
    return AsyncError(session.error!, session.stackTrace!);
  }
  final ({Comic comic, int totalPages})? view = viewShell.asData?.value;
  final ReadSessionContextData? sessionData = session.asData?.value;
  if (view == null || sessionData == null) {
    return const AsyncLoading<ReaderPageShellData>();
  }
  return AsyncData<ReaderPageShellData>((
    comic: view.comic,
    totalPages: view.totalPages,
    sessionContext: sessionData,
  ));
}

class _ReaderContentSlot extends ConsumerWidget {
  const _ReaderContentSlot({
    required this.viewKey,
    required this.routeContext,
    required this.readerFocusNode,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.seriesNavContext,
  });

  final ReaderControllerKey viewKey;
  final ReaderRouteContext routeContext;
  final FocusNode readerFocusNode;
  final int initialPage;
  final int? preferredPageIndex;
  final ReaderNavContextData? seriesNavContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReadingMode readingMode = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> asyncState) =>
            asyncState.asData?.value.readingMode ?? ReadingMode.paged,
      ),
    );
    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
    );
    Future<void> requestNextPage() => controller.requestNextPage(
      navContext: seriesNavContext,
      session: routeContext.session,
      router: GoRouter.of(context),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) {
        readerFocusNode.requestFocus();
        if (readingMode.isWebtoon) {
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
        readingMode: readingMode,
        onRequestNextPage: requestNextPage,
      ),
    );
  }
}

class _ReaderTopBarSlot extends ConsumerWidget {
  const _ReaderTopBarSlot({
    required this.viewKey,
    required this.title,
    required this.readerFullscreen,
    required this.navContext,
    required this.session,
    required this.seriesId,
    required this.routeContext,
  });

  final ReaderControllerKey viewKey;
  final String title;
  final bool readerFullscreen;
  final ReaderNavContextData? navContext;
  final ReadSessionRouteParams? session;
  final String? seriesId;
  final ReaderRouteContext routeContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showControls = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> asyncState) =>
            asyncState.asData?.value.showControls ?? false,
      ),
    );
    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
    );
    return ReaderTopBar(
      showControls: showControls,
      title: title,
      readerFullscreen: readerFullscreen,
      navContext: navContext,
      session: session,
      seriesId: seriesId,
      onExit: () async {
        await controller.executeExitReader(
          context: context,
          routeContext: routeContext,
        );
      },
      onToggleFullscreen: controller.toggleFullscreen,
    );
  }
}

class _ReaderBottomBarSlot extends ConsumerWidget {
  const _ReaderBottomBarSlot({
    required this.viewKey,
    required this.totalPages,
    required this.seriesNavContext,
    required this.routeContext,
  });

  final ReaderControllerKey viewKey;
  final int totalPages;
  final ReaderNavContextData? seriesNavContext;
  final ReaderRouteContext routeContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({bool showControls, int currentIndex, ReadingMode readingMode})
    chrome = ref.watch(
      readerControllerProvider(viewKey).select((
        AsyncValue<ReaderState> asyncState,
      ) {
        final ReaderState? state = asyncState.asData?.value;
        return (
          showControls: state?.showControls ?? false,
          currentIndex: state?.currentIndex ?? 1,
          readingMode: state?.readingMode ?? ReadingMode.paged,
        );
      }),
    );
    final bool readerAutoPlayEnabled = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> asyncState) =>
            asyncState.asData?.value.autoPlayEnabled ?? false,
      ),
    );
    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
    );
    Future<void> requestNextPage() => controller.requestNextPage(
      navContext: seriesNavContext,
      session: routeContext.session,
      router: GoRouter.of(context),
    );

    return ReaderBottomBar(
      showControls: chrome.showControls,
      currentIndex: chrome.currentIndex,
      totalPages: totalPages,
      readerAutoPlayEnabled: readerAutoPlayEnabled,
      showAutoPlayControls: chrome.readingMode.supportsAutoPlay,
      onPrevPage: controller.prevPage,
      onNextPage: requestNextPage,
      onSetIndex: controller.setIndex,
      onReaderAutoPlayEnabledChanged: (bool value) {
        controller.setAutoPlayEnabled(value);
      },
      showSeriesComicNav: seriesNavContext != null,
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
              final String targetComicId = seriesNavContext!.nextItem!.comicId;
              await ref
                  .read(readerSeriesNavigationProvider.notifier)
                  .switchComic(
                    router: GoRouter.of(context),
                    currentSession: routeContext.session,
                    targetComicId: targetComicId,
                  );
            }
          : null,
    );
  }
}

/// Isolates autoplay timer subscriptions so index ticks don't rebuild the page shell.
class _ReaderAutoPlayBinder extends HookConsumerWidget {
  const _ReaderAutoPlayBinder({
    required this.viewKey,
    required this.routeContext,
  });

  final ReaderControllerKey viewKey;
  final ReaderRouteContext routeContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
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
    final bool reduceMotion = reduceMotionOf(context);
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
    return const SizedBox.shrink();
  }
}
