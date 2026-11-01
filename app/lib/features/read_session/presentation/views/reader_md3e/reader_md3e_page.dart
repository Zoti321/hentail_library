import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/read_session/di/session_providers.dart';
import 'package:hentai_library/features/read_session/domain/reader_tap_zone.dart';
import 'package:hentai_library/features/read_session/presentation/reader_input.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/read_session_providers.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_page_facade.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_series_navigation.dart';
import 'package:hentai_library/features/read_session/presentation/widgets/reader_content.dart';
import 'package:hentai_library/features/read_session/presentation/widgets/reader_open_error_panel.dart';
import 'package:hentai_library/features/read_session/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_md3e/reader_md3e_cover_actions.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_md3e/reader_md3e_settings_sheet.dart';
import 'package:hentai_library/features/read_session/presentation/widgets/reader_auto_play_binder.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_md3e/reader_page.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_series_catalog_sheet.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_series_volume.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_status.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读页（MD3E 生产实现）：会话 / 翻页 / 续读 / 退出 / 全屏 / 键盘 / 自动播放 / 系列目录 / 封面设置。
///
/// 外壳为 [Md3eReaderPage]；页图由 Baseline [ReaderContent] 提供（三种视口保留）。
/// 设置面板为 MD3E 版（[ReaderMd3eSettingsSheet]）。
class ReaderMd3ePage extends HookConsumerWidget {
  const ReaderMd3ePage({
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
    final ThemeData theme = buildAppTheme(Brightness.dark);

    if (routeContext.comicId.isEmpty) {
      return Theme(
        data: theme,
        child: Scaffold(
          body: Center(child: Text(context.l10n.readerInvalidParams)),
        ),
      );
    }

    final ReaderPageFacadeState facade = ref.watch(
      readerPageFacadeProvider(
        comicId: routeContext.comicId,
        incognito: routeContext.incognito,
        startFromFirstPage: routeContext.startFromFirstPage,
      ),
    );
    final ReaderControllerKey viewKey = facade.viewKey;
    final AsyncValue<ReaderPageShellData> shellAsync = facade.shellAsync;
    final bool readerFullscreen = facade.readerFullscreen;
    final SeriesBoundaryPrompt seriesBoundaryPrompt =
        facade.seriesBoundaryPrompt;

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

    // 首个就绪帧冻结续读位置（与 Baseline 一致，避免内容构建前索引漂移）。
    if (loadedShell != null && frozenInitialPage.value == null) {
      final int openIndex =
          ref
              .read(readerControllerProvider(viewKey))
              .asData
              ?.value
              .currentIndex ??
          1;
      frozenOpenIndex.value = openIndex;
      frozenInitialPage.value = openIndex - 1;
    }

    useEffect(
      () {
        if (!readerReady ||
            loadedShell == null ||
            frozenOpenIndex.value == null) {
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
              .read(readerControllerProvider(viewKey))
              .asData
              ?.value
              .showControls ??
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
        showInfoToast(context, message);
      });
      return null;
    }, <Object?>[seriesBoundaryPrompt, context]);

    final ({
      bool showControls,
      int currentIndex,
      ReadingMode readingMode,
      bool autoPlayEnabled,
    })
    chrome = ref.watch(
      readerControllerProvider(viewKey)
          .select((AsyncValue<ReaderState> asyncState) {
            final ReaderState? state = asyncState.asData?.value;
            return (
              showControls: state?.showControls ?? false,
              currentIndex: state?.currentIndex ?? 1,
              readingMode: state?.readingMode ?? ReadingMode.paged,
              autoPlayEnabled: state?.autoPlayEnabled ?? false,
            );
          }),
    );

    Future<void> exitReader() => controller.executeExitReader(
      context: context,
      routeContext: routeContext,
    );

    return Theme(
      data: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) {
            return;
          }
          await exitReader();
        },
        child: M3ETheme(
          data: md3eWithAppFontFamily(M3ETheme.of(context)),
          child: Scaffold(
            backgroundColor: theme.hentai.readerBackground,
            body: shellAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace st) => ReaderOpenErrorPanel(
                error: e,
                onBackToDetail: () {
                  unawaited(exitReader());
                },
                onRetry: () {
                  ref.invalidate(
                    readerSessionOpenProvider(
                      comicId: routeContext.comicId,
                      incognito: routeContext.incognito,
                      startFromFirstPage: routeContext.startFromFirstPage,
                    ),
                  );
                  ref.invalidate(readerControllerProvider(viewKey));
                  ref.invalidate(
                    comicImagesProvider(comicId: routeContext.comicId),
                  );
                },
              ),
              data: (ReaderPageShellData shell) {
                if (shell.totalPages == 0) {
                  return Center(child: Text(context.l10n.readerNoImages));
                }
                final ReaderNavContextData? seriesNavContext =
                    shell.sessionContext.hasSeriesContext
                    ? shell.sessionContext.navContext
                    : null;

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

                final bool supportsAutoPlay =
                    chrome.readingMode.supportsAutoPlay;
                final String? seriesId = shell.sessionContext.seriesId;
                final bool isSeriesRead =
                    seriesId != null && seriesId.trim().isNotEmpty;

                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Md3eReaderPage(
                      title: shell.comic.title,
                      currentPage: chrome.currentIndex,
                      totalPages: shell.totalPages,
                      chromeVisible: chrome.showControls,
                      isFullscreen: readerFullscreen,
                      autoPlayEnabled:
                          supportsAutoPlay && chrome.autoPlayEnabled,
                      viewportStatus: Md3eReaderViewportStatus.ready,
                      onBack: () {
                        unawaited(exitReader());
                      },
                      onToggleFullscreen: () {
                        unawaited(controller.toggleFullscreen());
                      },
                      onPageChanged: controller.setIndex,
                      onPreviousPage: () {
                        unawaited(requestPrevPage());
                      },
                      onNextPage: () {
                        unawaited(requestNextPage());
                      },
                      onToggleChromeFromKeyboard: controller.toggleShowControls,
                      onAutoPlayChanged: supportsAutoPlay
                          ? controller.setAutoPlayEnabled
                          : null,
                      onOpenSettings: () {
                        unawaited(ReaderMd3eSettingsSheet.show(context));
                      },
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
                      contentBuilder: (FocusNode focusNode) =>
                          _ReaderMd3eContent(
                            viewKey: viewKey,
                            routeContext: routeContext,
                            focusNode: focusNode,
                            initialPage: frozenInitialPage.value ?? 0,
                            preferredPageIndex:
                                shell.sessionContext.preferredPageIndex,
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
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 页图内容层：真实视口 + 点击分区翻页（与 Baseline `_ReaderContentSlot` 行为一致）。
class _ReaderMd3eContent extends ConsumerWidget {
  const _ReaderMd3eContent({
    required this.viewKey,
    required this.routeContext,
    required this.focusNode,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.seriesNavContext,
  });

  final ReaderControllerKey viewKey;
  final ReaderRouteContext routeContext;
  final FocusNode focusNode;
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) {
        focusNode.requestFocus();
        if (readingMode.isWebtoon) {
          controller.toggleShowControls();
          return;
        }
        final ReaderTapZone zone = resolveReaderTapZone(
          globalX: details.globalPosition.dx,
          width: MediaQuery.sizeOf(context).width,
        );
        unawaited(
          controller.handleTapZone(
            zone,
            navContext: seriesNavContext,
            session: routeContext.session,
            router: GoRouter.of(context),
          ),
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
        onRequestNextPage: () => controller.requestNextPage(
          navContext: seriesNavContext,
          session: routeContext.session,
          router: GoRouter.of(context),
        ),
        onRequestPrevPage: () => controller.requestPrevPage(
          navContext: seriesNavContext,
          session: routeContext.session,
          router: GoRouter.of(context),
        ),
      ),
    );
  }
}

/// 打开系列目录；选中卷即切卷（与 Baseline 顶栏系列菜单共用 [readerSeriesNavigationProvider]）。
void _openSeriesCatalog(
  BuildContext context,
  WidgetRef ref, {
  required ReaderRouteContext routeContext,
  required ReaderNavContextData navContext,
}) {
  final List<Md3eReaderSeriesVolume> volumes = <Md3eReaderSeriesVolume>[
    for (final ReaderComicListItem item in navContext.items)
      Md3eReaderSeriesVolume(id: item.comicId, title: item.title),
  ];
  final GoRouter router = GoRouter.of(context);
  Md3eReaderSeriesCatalogSheet.show(
    context,
    volumes: volumes,
    currentVolumeId: routeContext.comicId,
    onVolumeSelected: (String targetComicId) {
      if (targetComicId == routeContext.comicId) {
        return;
      }
      unawaited(
        ref
            .read(readerSeriesNavigationProvider.notifier)
            .switchComic(
              router: router,
              currentSession: routeContext.session,
              targetComicId: targetComicId,
            ),
      );
    },
  );
}

/// 更多菜单：设为漫画封面；系列读取时额外提供设为系列封面。
List<M3EMenuNode> _buildMoreMenuEntries(
  BuildContext context,
  WidgetRef ref, {
  required ReaderControllerKey viewKey,
  required String? seriesId,
}) {
  final AppLocalizations l10n = context.l10n;
  return <M3EMenuNode>[
    M3EMenuEntry(
      label: l10n.readerSetComicCover,
      leading: const Icon(Icons.image_outlined),
      onPressed: () {
        unawaited(
          setComicCoverFromReader(context, ref, viewKey: viewKey, l10n: l10n),
        );
      },
    ),
    if (seriesId != null)
      M3EMenuEntry(
        label: l10n.readerSetSeriesCover,
        leading: const Icon(Icons.collections_outlined),
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
