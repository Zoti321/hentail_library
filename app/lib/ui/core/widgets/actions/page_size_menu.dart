import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_settings.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PageSizeMenuButton extends StatefulWidget {
  const PageSizeMenuButton({
    super.key,
    required this.activePageSize,
    required this.onSelected,
    this.layoutTier = LibraryLayoutTier.expanded,
  });

  final int activePageSize;
  final ValueChanged<int> onSelected;
  final LibraryLayoutTier layoutTier;

  @override
  State<PageSizeMenuButton> createState() => _PageSizeMenuButtonState();
}

class _PageSizeMenuButtonState extends State<PageSizeMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -32,
      menuBuilder: () => _PageSizeMenu(
        layoutTier: widget.layoutTier,
        activePageSize: widget.activePageSize,
        onSelected: (int pageSize) {
          _controller.hideMenu();
          widget.onSelected(pageSize);
        },
      ),
      child: GhostButton.icon(
        icon: LucideIcons.layoutGrid,
        tooltip: l10n.libraryPageSizeTooltip,
        semanticLabel: l10n.libraryPageSizeSemantic,
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.iconDefault,
        hoverColor: theme.hoverColor,
        overlayColor: theme.hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }
}

class _PageSizeMenu extends StatelessWidget {
  const _PageSizeMenu({
    required this.layoutTier,
    required this.activePageSize,
    required this.onSelected,
  });

  final LibraryLayoutTier layoutTier;
  final int activePageSize;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    return PopupMenuPanelShell(
      width: libraryPageSizeMenuWidth(layoutTier, viewportWidth),
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: kLibraryPageSizeOptions
              .map(
                (int pageSize) => _PageSizeMenuItem(
                  pageSize: pageSize,
                  isSelected: pageSize == activePageSize,
                  onTap: () => onSelected(pageSize),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _PageSizeMenuItem extends StatelessWidget {
  const _PageSizeMenuItem({
    required this.pageSize,
    required this.isSelected,
    required this.onTap,
  });

  final int pageSize;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? cs.primary.withAlpha(14) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isSelected ? Colors.transparent : cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '$pageSize',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? cs.primary : cs.hentai.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
