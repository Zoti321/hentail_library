import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_series_navigation.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_overflow_menu.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_series_nav.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_settings_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.showControls,
    required this.title,
    required this.readerFullscreen,
    required this.onExit,
    required this.onToggleFullscreen,
    this.navContext,
    this.session,
  });

  final bool showControls;
  final String title;
  final bool readerFullscreen;
  final ReaderNavContextData? navContext;
  final ReadSessionRouteParams? session;
  final Future<void> Function() onExit;
  final Future<void> Function() onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double topPadding = MediaQuery.of(context).padding.top + 24;
    final double targetWidth = ReaderFloatingPanel.targetBarWidth(context);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: showControls ? topPadding : topPadding - 20,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !showControls,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: showControls ? 1.0 : 0.0,
          child: Center(
            child: ReaderFloatingPanel(
              width: targetWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 8,
                children: <Widget>[
                  GhostButton.icon(
                    icon: LucideIcons.arrowLeft,
                    tooltip: '返回',
                    semanticLabel: '返回上一页',
                    iconSize: 16,
                    size: 28,
                    borderRadius: 8,
                    foregroundColor: cs.hentai.readerTextIconPrimary,
                    hoverColor: cs.hentai.readerPanelSubtle,
                    overlayColor: cs.hentai.readerPanelSubtle,
                    onPressed: () async {
                      await onExit();
                    },
                  ),
                  Expanded(
                    child: _ReaderTopBarTitle(
                      title: title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.hentai.readerTextIconPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  GhostButton.icon(
                    icon: readerFullscreen
                        ? LucideIcons.minimize2
                        : LucideIcons.maximize2,
                    tooltip: readerFullscreen ? '退出全屏' : '全屏',
                    semanticLabel: readerFullscreen ? '退出全屏' : '进入全屏',
                    iconSize: 16,
                    size: 32,
                    borderRadius: 8,
                    foregroundColor: cs.hentai.readerTextIconPrimary,
                    hoverColor: cs.hentai.readerPanelSubtle,
                    overlayColor: cs.hentai.readerPanelSubtle,
                    onPressed: () async {
                      await onToggleFullscreen();
                    },
                  ),
                  if (navContext != null && session != null)
                    ReaderSeriesMenuButton(
                      navContext: navContext!,
                      session: session!,
                    ),
                  GhostButton.icon(
                    icon: LucideIcons.settings,
                    tooltip: '阅读设置',
                    semanticLabel: '打开阅读设置',
                    iconSize: 16,
                    size: 32,
                    borderRadius: 8,
                    foregroundColor: cs.hentai.readerTextIconPrimary,
                    hoverColor: cs.hentai.readerPanelSubtle,
                    overlayColor: cs.hentai.readerPanelSubtle,
                    onPressed: () {
                      showReaderSettingsDialog(context);
                    },
                  ),
                  ReaderOverflowMenuButton(
                    comicId: session?.comicId ?? '',
                    seriesId: session?.seriesId,
                    incognito: session?.incognito ?? false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderTopBarTitle extends StatelessWidget {
  const _ReaderTopBarTitle({required this.title, required this.style});

  final String title;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      title,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!_isTextTruncated(
          context: context,
          maxWidth: constraints.maxWidth,
        )) {
          return text;
        }
        return Tooltip(
          message: title,
          waitDuration: const Duration(milliseconds: 400),
          child: text,
        );
      },
    );
  }

  bool _isTextTruncated({
    required BuildContext context,
    required double maxWidth,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: title, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }
}

/// 顶栏系列目录单按钮。
class ReaderSeriesMenuButton extends ConsumerStatefulWidget {
  const ReaderSeriesMenuButton({
    super.key,
    required this.navContext,
    required this.session,
  });

  final ReaderNavContextData navContext;
  final ReadSessionRouteParams session;

  @override
  ConsumerState<ReaderSeriesMenuButton> createState() =>
      _ReaderSeriesMenuButtonState();
}

class _ReaderSeriesMenuButtonState
    extends ConsumerState<ReaderSeriesMenuButton> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  Future<void> _switchToComic(String targetComicId) async {
    if (targetComicId == widget.session.comicId) {
      return;
    }
    await ref
        .read(readerSeriesNavigationProvider.notifier)
        .switchComic(
          router: GoRouter.of(context),
          currentSession: widget.session,
          targetComicId: targetComicId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPopupMenu(
      controller: _menuController,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -14,
      menuBuilder: () => ReaderSeriesMenu(
        navContext: widget.navContext,
        onSelect: (String targetComicId) {
          _menuController.hideMenu();
          _switchToComic(targetComicId);
        },
      ),
      child: GhostButton.icon(
        icon: LucideIcons.list,
        tooltip: '系列目录',
        semanticLabel: '系列目录',
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.readerTextIconPrimary,
        hoverColor: cs.hentai.readerPanelSubtle,
        overlayColor: cs.hentai.readerPanelSubtle,
        onPressed: () => _menuController.toggleMenu(),
      ),
    );
  }
}
