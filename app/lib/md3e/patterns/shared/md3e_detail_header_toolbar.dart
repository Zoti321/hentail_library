import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 漫画 / 系列详情顶栏左侧：返回、更多、编辑。
class Md3eDetailHeaderToolbar extends StatelessWidget {
  const Md3eDetailHeaderToolbar({
    super.key,
    this.onBack,
    this.onEdit,
    required this.editTooltip,
    this.moreMenuEntries = const <M3EMenuNode>[],
  });

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final String editTooltip;
  final List<M3EMenuNode> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color iconColor = scheme.onSurfaceVariant;
    const double iconSize = Md3eLibraryPageHeaderMetrics.actionIconSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _iconButton(
          icon: Symbols.arrow_back,
          tooltip: l10n.shellBack,
          semanticLabel: l10n.shellBack,
          onPressed: onBack,
          iconColor: iconColor,
          iconSize: iconSize,
        ),
        if (moreMenuEntries.isEmpty)
          _iconButton(
            icon: Icons.more_vert,
            tooltip: l10n.metadataMoreActions,
            semanticLabel: l10n.metadataMoreActions,
            onPressed: null,
            iconColor: iconColor,
            iconSize: iconSize,
          )
        else
          Md3eAnchoredMenu(
            position: M3EMenuAnchorPosition.bottomStart,
            children: moreMenuEntries,
            anchorBuilder: (BuildContext context, VoidCallback open) {
              return _iconButton(
                icon: Icons.more_vert,
                tooltip: l10n.metadataMoreActions,
                semanticLabel: l10n.metadataMoreActions,
                onPressed: open,
                iconColor: iconColor,
                iconSize: iconSize,
              );
            },
          ),
        _iconButton(
          icon: Symbols.edit,
          tooltip: editTooltip,
          semanticLabel: editTooltip,
          onPressed: onEdit,
          iconColor: iconColor,
          iconSize: iconSize,
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required String semanticLabel,
    required VoidCallback? onPressed,
    required Color iconColor,
    required double iconSize,
  }) {
    return M3EIconButton(
      icon: Icon(icon, size: iconSize, color: iconColor),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    );
  }
}
