import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reader/presentation/input/reader_tap_zone.dart';
import 'package:hentai_library/features/reader/presentation/reader_input.dart';
import 'package:hentai_library/features/reader/presentation/navigation/apply_reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_chrome_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_page_shell.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_series_navigation.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/view_models/series_reader_provider.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_content.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_open_error_panel.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_cover_actions.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_settings_sheet.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_auto_play_binder.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_layout.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_series_catalog_sheet.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_series_volume.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_viewport_status.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/public/reading_preferences_providers.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/features/reader/presentation/views/reader/reader_layout.dart';

/// 阅读页（MD3E 生产实现）：会话 / 翻页 / 续读 / 退出 / 全屏 / 键盘 / 自动播放 / 系列目录 / 封面设置。
///
/// 外壳为 [ReaderLayout]；页图由 Baseline [ReaderContent] 提供（三种视口保留）。
/// 设置面板为 MD3E 版（[ReaderSettingsSheet]）。
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
    // 强制暗色沉浸壳，但 seed 跟当前应用主题（含动态配色）对齐。
    final ThemeData ambient = Theme.of(context);
    final ThemeData theme = ambient.brightness == Brightness.dark
        ? ambient
        : buildAppTheme(Brightness.dark, seed: ambient.colorScheme.primary);

    if (routeContext.comicId.isEmpty) {
      return Theme(
        data: theme,
        child: Scaffold(
          body: Center(child: Text(context.l10n.readerInvalidParams)),
        ),
      );
    }

    final ReaderViewModelKey viewKey = readerViewModelKey(
      routeContext.comicId,
      incognito: routeContext.incognito,
      startFromFirstPage: routeContext.startFromFirstPage,
    );
    final AsyncValue<ReaderPageViewShell> viewShellAsync = ref.watch(
      readerViewModelProvider(viewKey)
          .select((AsyncValue<ReaderUiState> asyncState) {
            if (asyncState.hasError) {
              return AsyncError<ReaderPageViewShell>(
                asyncState.error!,
                asyncState.stackTrace!,
              );
            }
            final ReaderUiState? state = asyncState.asData?.value;
            if (state == null) {
              return const AsyncLoading<ReaderPageViewShell>();
            }
            return AsyncData<ReaderPageViewShell>((
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
    final AsyncValue<ReaderPageShellData> shellAsync = combineReaderPageShell(
      viewShellAsync,
      sessionAsync,
    );
    final bool readerFullscreen = ref.watch(readerChromeNotifierProvider);
    final SeriesBoundaryPrompt seriesBoundaryPrompt = ref.watch(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> asyncState) =>
            asyncState.asData?.value.seriesBoundaryPrompt ??
            SeriesBoundaryPrompt.none,
      ),
    );

    final bool readerReady = shellAsync.hasValue;
    final ReaderPageShellData? loadedShell = shellAsync.asData?.value;
    final ObjectRef<int?> frozenInitialPage = useRef<int?>(null);
    final ObjectRef<String?> frozenSessionKey = useRef<String?>(null);
    final String sessionKey =
        '${routeContext.comicId}|${routeContext.incognito}|${routeContext.startFromFirstPage}';
    if (frozenSessionKey.value != sessionKey) {
      frozenSessionKey.value = sessionKey;
      frozenInitialPage.value = null;
    }

    // 首个就绪帧冻结续读位置（与 Baseline 一致，避免内容构建前索引漂移）。
    if (loadedShell != null && frozenInitialPage.value == null) {
      final int openIndex =
          ref
              .read(readerViewModelProvider(viewKey))
              .asData
              ?.value
              .currentIndex ??
          1;
      frozenInitialPage.value = openIndex - 1;
    }

    final ReaderViewModel viewModel = ref.read(
      readerViewModelProvider(viewKey).notifier,
    );
    final ObjectRef<bool> hasAppliedKeepControls = useRef<bool>(false);

    // 前台计时：进后台结算活动时长，回前台重新开表。
    useEffect(() {
      final AppLifecycleListener listener = AppLifecycleListener(
        onPause: () => unawaited(viewModel.pauseForeground()),
        onResume: viewModel.resumeForeground,
      );
      return listener.dispose;
    }, <Object?>[viewModel]);

    useEffect(() {
      if (!keepControlsOpen || hasAppliedKeepControls.value) {
        return null;
      }
      if (!readerReady) {
        return null;
      }
      hasAppliedKeepControls.value = true;
      final bool showControls =
          ref
              .read(readerViewModelProvider(viewKey))
              .asData
              ?.value
              .showControls ??
          false;
      if (showControls) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.setShowControls(true);
      });
      return null;
    }, <Object?>[keepControlsOpen, readerReady, viewModel]);

    useEffect(() {
      if (seriesBoundaryPrompt == SeriesBoundaryPrompt.none) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final String message = switch (seriesBoundaryPrompt) {
          SeriesBoundaryPrompt.advance =>
            context.l10n.readerSeriesAdvancePrompt,
          SeriesBoundaryPrompt.retreat =>
            context.l10n.readerSeriesRetreatPrompt,
          SeriesBoundaryPrompt.none => '',
        };
        if (message.isEmpty) {
          return;
        }
        showInfoSnackbar(context, message);
      });
      return null;
    }, <Object?>[seriesBoundaryPrompt, context]);

    Future<void> exitReader() async {
      final ReaderExitIntent intent = await viewModel.prepareExitReader(
        routeContext: routeContext,
        canPop: appNavigatorOf(context).canPop(),
      );
      applyReaderExitIntent(context, intent);
    }

    return Theme(
      data: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) =>
            _handlePopInvoked(didPop, exitReader),
        child: M3ETheme(
          data: withAppFontFamily(M3ETheme.of(context)),
          child: Scaffold(
            backgroundColor: theme.reader.readerBackground,
            body: shellAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace st) => ReaderOpenErrorPanel(
                error: e,
                onBackToDetail: () => unawaited(exitReader()),
                onRetry: () => _retryOpen(ref, viewKey, routeContext),
              ),
              // 翻页 chrome 下沉到 [_ReaderReadyBody]，避免根节点订阅 currentIndex。
              data: (ReaderPageShellData shell) => _ReaderReadyBody(
                viewKey: viewKey,
                routeContext: routeContext,
                shell: shell,
                readerFullscreen: readerFullscreen,
                initialPage: frozenInitialPage.value ?? 0,
                onExit: exitReader,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePopInvoked(
    bool didPop,
    Future<void> Function() exitReader,
  ) async {
    if (didPop) {
      return;
    }
    await exitReader();
  }

  void _retryOpen(
    WidgetRef ref,
    ReaderViewModelKey viewKey,
    ReaderRouteContext routeContext,
  ) {
    ref.invalidate(
      readerSessionOpenProvider(
        comicId: routeContext.comicId,
        incognito: routeContext.incognito,
        startFromFirstPage: routeContext.startFromFirstPage,
      ),
    );
    ref.invalidate(readerViewModelProvider(viewKey));
    ref.invalidate(comicImagesProvider(comicId: routeContext.comicId));
  }
}

/// 就绪态阅读壳：仅此处订阅翻页 / chrome，父级 [ReaderPage] 只 watch 外壳字段。
class _ReaderReadyBody extends ConsumerWidget {
  const _ReaderReadyBody({
    required this.viewKey,
    required this.routeContext,
    required this.shell,
    required this.readerFullscreen,
    required this.initialPage,
    required this.onExit,
  });

  final ReaderViewModelKey viewKey;
  final ReaderRouteContext routeContext;
  final ReaderPageShellData shell;
  final bool readerFullscreen;
  final int initialPage;
  final Future<void> Function() onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shell.totalPages == 0) {
      return Center(child: Text(context.l10n.readerNoImages));
    }

    final ({
      bool showControls,
      int currentIndex,
      ReadingMode readingMode,
      bool autoPlayEnabled,
    })
    chrome = ref.watch(
      readerViewModelProvider(viewKey)
          .select((AsyncValue<ReaderUiState> asyncState) {
            final ReaderUiState? state = asyncState.asData?.value;
            return (
              showControls: state?.showControls ?? false,
              currentIndex: state?.currentIndex ?? 1,
              readingMode: state?.readingMode ?? ReadingMode.paged,
              autoPlayEnabled: state?.autoPlayEnabled ?? false,
            );
          }),
    );

    final ReaderViewModel viewModel = ref.read(
      readerViewModelProvider(viewKey).notifier,
    );
    final ReaderNavContextData? seriesNavContext =
        shell.sessionContext.hasSeriesContext
        ? shell.sessionContext.navContext
        : null;

    Future<void> requestNextPage() async {
      final ReaderReplaceReaderRouteIntent? intent = await viewModel
          .requestNextPage(
            navContext: seriesNavContext,
            session: routeContext.session,
          );
      applyReaderNavigationIntent(context, intent);
    }

    Future<void> requestPrevPage() async {
      final ReaderReplaceReaderRouteIntent? intent = await viewModel
          .requestPrevPage(
            navContext: seriesNavContext,
            session: routeContext.session,
          );
      applyReaderNavigationIntent(context, intent);
    }

    final bool supportsAutoPlay = chrome.readingMode.supportsAutoPlay;
    final int autoPlayIntervalSeconds = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences prefs) => prefs.autoPlayIntervalSeconds,
      ),
    );
    final String? seriesId = shell.sessionContext.seriesId;
    final bool isSeriesRead = seriesId != null && seriesId.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ReaderLayout(
          title: shell.comic.title,
          currentPage: chrome.currentIndex,
          totalPages: shell.totalPages,
          chromeVisible: chrome.showControls,
          isFullscreen: readerFullscreen,
          autoPlayEnabled: supportsAutoPlay && chrome.autoPlayEnabled,
          autoPlayIntervalSeconds: autoPlayIntervalSeconds,
          viewportStatus: ReaderViewportStatus.ready,
          onBack: () => unawaited(onExit()),
          onToggleFullscreen: () => unawaited(viewModel.toggleFullscreen()),
          onPageChanged: viewModel.setIndex,
          onPreviousPage: () => unawaited(requestPrevPage()),
          onNextPage: () => unawaited(requestNextPage()),
          onToggleChromeFromKeyboard: viewModel.toggleShowControls,
          onAutoPlayChanged: supportsAutoPlay
              ? viewModel.setAutoPlayEnabled
              : null,
          onOpenSettings: () => unawaited(ReaderSettingsSheet.show(context)),
          onOpenSeriesCatalog: seriesNavContext == null
              ? null
              : () => _openSeriesCatalog(
                  context,
                  ref,
                  routeContext: routeContext,
                  navContext: seriesNavContext,
                ),
          moreMenuEntries: _buildMoreMenuEntries(
            context,
            ref,
            viewKey: viewKey,
            seriesId: isSeriesRead ? seriesId : null,
          ),
          contentBuilder: (FocusNode focusNode) => _ReaderPageContent(
            viewKey: viewKey,
            routeContext: routeContext,
            focusNode: focusNode,
            initialPage: initialPage,
            preferredPageIndex: shell.sessionContext.preferredPageIndex,
            seriesNavContext: seriesNavContext,
          ),
        ),
        ReaderAutoPlayBinder(
          viewKey: viewKey,
          routeContext: routeContext,
          seriesNavContext: seriesNavContext,
        ),
      ],
    );
  }
}

/// 页图内容层：真实视口 + 点击分区翻页（与 Baseline `_ReaderContentSlot` 行为一致）。
class _ReaderPageContent extends ConsumerWidget {
  const _ReaderPageContent({
    required this.viewKey,
    required this.routeContext,
    required this.focusNode,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.seriesNavContext,
  });

  final ReaderViewModelKey viewKey;
  final ReaderRouteContext routeContext;
  final FocusNode focusNode;
  final int initialPage;
  final int? preferredPageIndex;
  final ReaderNavContextData? seriesNavContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReadingMode readingMode = ref.watch(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> asyncState) =>
            asyncState.asData?.value.readingMode ?? ReadingMode.paged,
      ),
    );
    final ReaderViewModel viewModel = ref.read(
      readerViewModelProvider(viewKey).notifier,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) =>
          _handleTapUp(context, details, viewModel, readingMode),
      child: ReaderContent(
        key: ValueKey<String>(routeContext.comicId),
        comicId: routeContext.comicId,
        incognito: routeContext.incognito,
        startFromFirstPage: routeContext.startFromFirstPage,
        initialPage: initialPage,
        preferredPageIndex: preferredPageIndex,
        readingMode: readingMode,
        onRequestNextPage: () =>
            _requestNextPage(context, viewModel, seriesNavContext),
        onRequestPrevPage: () =>
            _requestPrevPage(context, viewModel, seriesNavContext),
      ),
    );
  }

  void _handleTapUp(
    BuildContext context,
    TapUpDetails details,
    ReaderViewModel viewModel,
    ReadingMode readingMode,
  ) {
    focusNode.requestFocus();
    if (readingMode.isWebtoon) {
      viewModel.toggleShowControls();
      return;
    }
    final ReaderTapZone zone = resolveReaderTapZone(
      globalX: details.globalPosition.dx,
      width: MediaQuery.sizeOf(context).width,
    );
    unawaited(() async {
      final ReaderReplaceReaderRouteIntent? intent = await viewModel
          .handleTapZone(
            zone,
            navContext: seriesNavContext,
            session: routeContext.session,
          );
      applyReaderNavigationIntent(context, intent);
    }());
  }

  Future<void> _requestNextPage(
    BuildContext context,
    ReaderViewModel viewModel,
    ReaderNavContextData? navContext,
  ) async {
    final ReaderReplaceReaderRouteIntent? intent = await viewModel
        .requestNextPage(navContext: navContext, session: routeContext.session);
    applyReaderNavigationIntent(context, intent);
  }

  Future<void> _requestPrevPage(
    BuildContext context,
    ReaderViewModel viewModel,
    ReaderNavContextData? navContext,
  ) async {
    final ReaderReplaceReaderRouteIntent? intent = await viewModel
        .requestPrevPage(navContext: navContext, session: routeContext.session);
    applyReaderNavigationIntent(context, intent);
  }
}

/// 打开系列目录；选中卷即切卷（与 Baseline 顶栏系列菜单共用 [readerSeriesNavigationProvider]）。
void _openSeriesCatalog(
  BuildContext context,
  WidgetRef ref, {
  required ReaderRouteContext routeContext,
  required ReaderNavContextData navContext,
}) {
  final List<ReaderSeriesVolume> volumes = <ReaderSeriesVolume>[
    for (final ReaderComicListItem item in navContext.items)
      ReaderSeriesVolume(id: item.comicId, title: item.title),
  ];
  ReaderSeriesCatalogSheet.show(
    context,
    volumes: volumes,
    currentVolumeId: routeContext.comicId,
    onVolumeSelected: (String targetComicId) {
      if (targetComicId == routeContext.comicId) {
        return;
      }
      unawaited(() async {
        final ReaderReplaceReaderRouteIntent? intent = await ref
            .read(readerSeriesNavigationProvider.notifier)
            .prepareSwitchComic(
              currentSession: routeContext.session,
              targetComicId: targetComicId,
            );
        applyReaderNavigationIntent(context, intent);
      }());
    },
  );
}

/// 更多菜单：设为漫画封面；系列读取时额外提供设为系列封面。
List<M3EMenuNode> _buildMoreMenuEntries(
  BuildContext context,
  WidgetRef ref, {
  required ReaderViewModelKey viewKey,
  required String? seriesId,
}) {
  final AppLocalizations l10n = context.l10n;
  return <M3EMenuNode>[
    M3EMenuEntry(
      label: l10n.readerSetComicCover,
      leading: const Icon(Symbols.image),
      onPressed: () {
        unawaited(
          setComicCoverFromReader(context, ref, viewKey: viewKey, l10n: l10n),
        );
      },
    ),
    if (seriesId != null)
      M3EMenuEntry(
        label: l10n.readerSetSeriesCover,
        leading: const Icon(Symbols.collections),
        onPressed: () {
          unawaited(
            setSeriesCoverFromReader(
              context,
              ref,
              viewKey: viewKey,
              seriesId: seriesId,
              l10n: l10n,
            ),
          );
        },
      ),
  ];
}
