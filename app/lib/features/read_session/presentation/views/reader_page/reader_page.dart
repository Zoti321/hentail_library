import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hentai_library/features/read_session/domain/read_session.dart';
import 'package:hentai_library/features/read_session/domain/reader_tap_zone.dart';
import 'package:hentai_library/shared/ui/motion/app_motion.dart';
import 'package:hentai_library/features/read_session/presentation/reader_input.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_bottom_bar.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_content.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_open_error_panel.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_top_bar.dart';
import 'package:hentai_library/features/read_session/di/session_providers.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/read_session_providers.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_page_facade.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';

part 'reader_page_slots.dart';

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

    if (routeContext.comicId.isEmpty) {
      return Theme(
        data: buildAppTheme(Brightness.dark),
        child: Scaffold(
          body: Center(child: Text(context.l10n.readerInvalidParams)),
        ),
      );
    }

    final ThemeData theme = buildAppTheme(Brightness.dark);

    // 根节点唯一 watch：外壳 / 全屏 / 切卷提示均由 Facade 聚合（ADR-0017）。
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

    // Freeze resume index synchronously on first ready frame (before content builds).
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

    void dispatchReaderKeyboard(LogicalKeyboardKey key) {
      final ReaderState? readerState = ref
          .read(readerControllerProvider(viewKey))
          .asData
          ?.value;
      final bool showControls = readerState?.showControls ?? false;
      final ReaderKeyboardCommand? command = readerKeyboardCommandFor(
        key,
        showControls: showControls,
      );
      if (command == null) {
        return;
      }
      switch (command) {
        case ReaderKeyboardCommand.prevPage:
          final ReaderPageShellData? shell = shellAsync.asData?.value;
          unawaited(
            controller.requestPrevPage(
              navContext: shell != null && shell.sessionContext.hasSeriesContext
                  ? shell.sessionContext.navContext
                  : null,
              session: routeContext.session,
              router: GoRouter.of(context),
            ),
          );
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
        case ReaderKeyboardCommand.toggleAutoPlay:
          final ReaderState? state = readerState;
          if (state == null || !state.readingMode.supportsAutoPlay) {
            return;
          }
          controller.setAutoPlayEnabled(!state.autoPlayEnabled);
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
              backgroundColor: theme.hentai.readerBackground,
              body: shellAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => ReaderOpenErrorPanel(
                  error: e,
                  onBackToDetail: () {
                    unawaited(
                      controller.executeExitReader(
                        context: context,
                        routeContext: routeContext,
                      ),
                    );
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
                        preferredPageIndex:
                            shell.sessionContext.preferredPageIndex,
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
                        seriesNavContext: seriesNavContext,
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
