import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kMetadataRowOverflowButtonSize = 32;
const double _kMetadataRowMenuMinWidth = 120;
const double _kMetadataRowMenuViewportMargin = 32;
const double _kMetadataRowMenuItemHorizontalPadding = 12;
const double _kMetadataRowMenuItemVerticalPadding = 10;
const double _kMetadataRowMenuIconSize = 16;
const double _kMetadataRowMenuIconSpacing = 10;

class MetadataPanelRowActions extends StatelessWidget {
  const MetadataPanelRowActions({
    required this.layoutTier,
    required this.onRename,
    required this.onDelete,
    this.iconButtonRadius = 8,
    this.iconButtonSize = 28,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final double iconButtonRadius;
  final double iconButtonSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (metadataRowUsesOverflowMenu(layoutTier)) {
      return _MetadataRowOverflowButton(
        onRename: onRename,
        onDelete: onDelete,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.squarePen,
          iconSize: 16,
          size: iconButtonSize,
          borderRadius: iconButtonRadius,
          tooltip: '重命名',
          delayTooltipThreeSeconds: true,
          hoverColor: cs.primary.withAlpha(10),
          overlayColor: cs.primary.withAlpha(14),
          onPressed: onRename,
        ),
        GhostButton.icon(
          tooltip: '删除',
          semanticLabel: '删除',
          icon: LucideIcons.trash2,
          iconSize: 16,
          size: iconButtonSize,
          borderRadius: iconButtonRadius,
          foregroundColor: cs.error,
          hoverColor: cs.primary.withAlpha(10),
          overlayColor: cs.primary.withAlpha(14),
          delayTooltipThreeSeconds: true,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _MetadataRowOverflowButton extends StatefulWidget {
  const _MetadataRowOverflowButton({
    required this.onRename,
    required this.onDelete,
  });

  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<_MetadataRowOverflowButton> createState() =>
      _MetadataRowOverflowButtonState();
}

class _MetadataRowOverflowButtonState extends State<_MetadataRowOverflowButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -24,
      menuBuilder: () => _MetadataRowOverflowMenu(
        onRename: () {
          _controller.hideMenu();
          widget.onRename();
        },
        onDelete: () {
          _controller.hideMenu();
          widget.onDelete();
        },
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: '更多操作',
        semanticLabel: '更多操作',
        iconSize: 16,
        size: _kMetadataRowOverflowButtonSize,
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

class _MetadataRowOverflowMenu extends StatelessWidget {
  const _MetadataRowOverflowMenu({
    required this.onRename,
    required this.onDelete,
  });

  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PopupMenuPanelShell(
      width: _metadataRowMenuWidth(context),
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _MetadataRowMenuItem(
              icon: LucideIcons.squarePen,
              label: '重命名',
              onTap: onRename,
            ),
            _MetadataRowMenuItem(
              icon: LucideIcons.trash2,
              label: '删除',
              foregroundColor: cs.error,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataRowMenuItem extends StatelessWidget {
  const _MetadataRowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color iconColor = foregroundColor ?? cs.hentai.iconDefault;
    final Color textColor = foregroundColor ?? cs.hentai.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _kMetadataRowMenuItemHorizontalPadding,
            vertical: _kMetadataRowMenuItemVerticalPadding,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: _kMetadataRowMenuIconSize, color: iconColor),
              const SizedBox(width: _kMetadataRowMenuIconSpacing),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _metadataRowMenuWidth(BuildContext context) {
  const List<String> labels = <String>['重命名', '删除'];
  const TextStyle textStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  final double maxWidth =
      MediaQuery.sizeOf(context).width - _kMetadataRowMenuViewportMargin;
  double measuredWidth = 0;
  for (final String label in labels) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final double itemWidth =
        _kMetadataRowMenuItemHorizontalPadding * 2 +
        _kMetadataRowMenuIconSize +
        _kMetadataRowMenuIconSpacing +
        painter.width;
    if (itemWidth > measuredWidth) {
      measuredWidth = itemWidth;
    }
  }
  return measuredWidth.clamp(_kMetadataRowMenuMinWidth, maxWidth).toDouble();
}
