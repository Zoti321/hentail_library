part of 'reader_page.dart';

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
    Future<void> requestPrevPage() => controller.requestPrevPage(
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
        onRequestPrevPage: requestPrevPage,
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
      readerControllerProvider(viewKey)
          .select((AsyncValue<ReaderState> asyncState) {
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
    Future<void> requestPrevPage() => controller.requestPrevPage(
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
      onPrevPage: () {
        unawaited(requestPrevPage());
      },
      onNextPage: requestNextPage,
      onSetIndex: controller.setIndex,
      onReaderAutoPlayEnabledChanged: (bool value) {
        controller.setAutoPlayEnabled(value);
      },
    );
  }
}

/// Isolates autoplay timer subscriptions so index ticks don't rebuild the page shell.
class _ReaderAutoPlayBinder extends HookConsumerWidget {
  const _ReaderAutoPlayBinder({
    required this.viewKey,
    required this.routeContext,
    required this.seriesNavContext,
  });

  final ReaderControllerKey viewKey;
  final ReaderRouteContext routeContext;
  final ReaderNavContextData? seriesNavContext;

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
      appSettingsStateProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readerAutoPlayIntervalSeconds ?? 5,
      ),
    );
    final AutoPlayMode autoPlayMode = ref.watch(
      appSettingsStateProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.autoPlayMode ?? kDefaultAutoPlayMode,
      ),
    );
    final ({int currentIndex, int totalPages, ReadingMode readingMode})?
    autoPlayState = ref.watch(
      readerControllerProvider(viewKey)
          .select((AsyncValue<ReaderState> asyncState) {
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
    final String? nextComicId = seriesNavContext?.nextItem?.comicId;
    final List<ReaderComicListItem>? seriesItems = seriesNavContext?.items;
    final String? firstComicId = seriesItems != null && seriesItems.isNotEmpty
        ? seriesItems.first.comicId
        : null;

    useEffect(
      () {
        final bool canStartAutoPlay =
            readerAutoPlayAllowed(
              userEnabled: readerAutoPlayEnabled,
              reduceMotion: reduceMotion,
            ) &&
            autoPlayState != null &&
            autoPlayState.readingMode.supportsAutoPlay &&
            autoPlayState.totalPages > 0;
        if (!canStartAutoPlay) {
          return null;
        }
        final Duration interval = Duration(
          seconds: readerAutoPlayIntervalSeconds,
        );
        Timer? timer;
        timer = Timer.periodic(interval, (_) {
          if (!context.mounted) {
            timer?.cancel();
            return;
          }
          if (ref.read(readerControllerProvider(viewKey)).asData?.value ==
              null) {
            return;
          }
          final GoRouter router = GoRouter.of(context);
          unawaited(() async {
            final bool keepTicking = await controller.advanceAutoPlay(
              navContext: seriesNavContext,
              session: routeContext.session,
              router: router,
            );
            if (!keepTicking) {
              timer?.cancel();
            }
          }());
        });
        return () {
          timer?.cancel();
        };
      },
      <Object?>[
        readerAutoPlayEnabled,
        readerAutoPlayIntervalSeconds,
        autoPlayMode,
        autoPlayState?.currentIndex,
        autoPlayState?.totalPages,
        autoPlayState?.readingMode,
        nextComicId,
        firstComicId,
        routeContext.comicId,
        controller,
        ref,
        reduceMotion,
      ],
    );
    return const SizedBox.shrink();
  }
}
