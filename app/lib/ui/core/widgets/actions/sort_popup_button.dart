import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_sort_controls.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SortPopupButton extends StatefulHookConsumerWidget {
  const SortPopupButton({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SortPopupButtonState();
}

class _SortPopupButtonState extends ConsumerState<SortPopupButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -16,
      menuBuilder: () => _SortMenu(menuController: _controller),
      child: GhostButton.icon(
        icon: LucideIcons.arrowDownWideNarrow,
        tooltip: '排序',
        semanticLabel: '打开排序',
        iconSize: 16,
        size: 28,
        borderRadius: tokens.radius.sm,
        foregroundColor: theme.colorScheme.hentai.iconDefault,
        hoverColor: theme.hoverColor,
        overlayColor: theme.hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.showMenu(),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.menuController});

  final CustomPopupMenuController menuController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return PopupMenuPanelShell(
      width: 320,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.hentai.borderSubtle,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.swap_vert,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '排序与视图',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.hentai.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: LibrarySortControls(),
          ),
        ],
      ),
    );
  }
}
