import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_series_navigation.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kReaderSeriesMenuWidth = 320;
const double _kReaderSeriesMenuMaxHeight = 360;

class ReaderSeriesNav extends ConsumerStatefulWidget {
  const ReaderSeriesNav({
    super.key,
    required this.navContext,
    required this.session,
  });

  final ReaderNavContextData navContext;
  final ReadSessionRouteParams session;

  @override
  ConsumerState<ReaderSeriesNav> createState() => _ReaderSeriesNavState();
}

class _ReaderSeriesNavState extends ConsumerState<ReaderSeriesNav> {
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
    final ReaderComicListItem? previous = widget.navContext.previousItem;
    final ReaderComicListItem? next = widget.navContext.nextItem;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.chevronLeft,
          tooltip: '上一卷',
          semanticLabel: '系列上一卷',
          iconSize: 16,
          size: 28,
          borderRadius: 8,
          foregroundColor: cs.hentai.readerTextIconPrimary,
          hoverColor: cs.hentai.readerPanelSubtle,
          overlayColor: cs.hentai.readerPanelSubtle,
          onPressed: previous == null
              ? null
              : () => _switchToComic(previous.comicId),
        ),
        CustomPopupMenu(
          controller: _menuController,
          barrierColor: Colors.transparent,
          pressType: PressType.singleClick,
          showArrow: false,
          verticalMargin: -14,
          menuBuilder: () => _ReaderSeriesMenu(
            navContext: widget.navContext,
            onSelect: (String targetComicId) {
              _menuController.hideMenu();
              _switchToComic(targetComicId);
            },
          ),
          child: GhostButton.icon(
            icon: LucideIcons.menu,
            tooltip: '系列目录',
            semanticLabel: '系列目录',
            iconSize: 16,
            size: 28,
            borderRadius: 8,
            foregroundColor: cs.hentai.readerTextIconPrimary,
            hoverColor: cs.hentai.readerPanelSubtle,
            overlayColor: cs.hentai.readerPanelSubtle,
            onPressed: () => _menuController.toggleMenu(),
          ),
        ),
        GhostButton.icon(
          icon: LucideIcons.chevronRight,
          tooltip: '下一卷',
          semanticLabel: '系列下一卷',
          iconSize: 16,
          size: 28,
          borderRadius: 8,
          foregroundColor: cs.hentai.readerTextIconPrimary,
          hoverColor: cs.hentai.readerPanelSubtle,
          overlayColor: cs.hentai.readerPanelSubtle,
          onPressed: next == null ? null : () => _switchToComic(next.comicId),
        ),
      ],
    );
  }
}

class _ReaderSeriesMenu extends StatelessWidget {
  const _ReaderSeriesMenu({required this.navContext, required this.onSelect});

  final ReaderNavContextData navContext;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuPanelShell(
      width: _kReaderSeriesMenuWidth,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: _kReaderSeriesMenuMaxHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: navContext.items
                .map(
                  (ReaderComicListItem item) => _ReaderSeriesMenuItem(
                    item: item,
                    displayIndex: navContext.items.indexOf(item) + 1,
                    isCurrent:
                        item.comicId ==
                        navContext.items[navContext.currentIndex].comicId,
                    onTap: () => onSelect(item.comicId),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ReaderSeriesMenuItem extends StatelessWidget {
  const _ReaderSeriesMenuItem({
    required this.item,
    required this.displayIndex,
    required this.isCurrent,
    required this.onTap,
  });

  final ReaderComicListItem item;
  final int displayIndex;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String label = '$displayIndex-${item.title}';
    final TextStyle textStyle = TextStyle(
      fontSize: tokens.text.bodySm,
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
      color: isCurrent ? cs.primary : cs.hentai.textPrimary,
      height: 1.35,
    );
    return Material(
      color: isCurrent ? cs.primary.withAlpha(14) : Colors.transparent,
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        hoverColor: isCurrent ? Colors.transparent : cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Tooltip(
            message: label,
            waitDuration: const Duration(milliseconds: 500),
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
