import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/components/scaffold/library_page_header_metrics.dart';
import 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 详情顶栏共用图标按钮。
Widget detailHeaderIconButton({
  required IconData icon,
  required String tooltip,
  required String semanticLabel,
  required VoidCallback? onPressed,
  required Color iconColor,
}) {
  const double iconSize = LibraryPageHeaderMetrics.actionIconSize;
  return M3EIconButton(
    icon: Icon(icon, size: iconSize, color: iconColor),
    variant: M3EIconButtonVariant.standard,
    size: M3EIconButtonSize.sm,
    tooltip: tooltip,
    semanticLabel: semanticLabel,
    onPressed: onPressed,
  );
}

/// 详情顶栏左侧返回。
class DetailHeaderBackButton extends StatelessWidget {
  const DetailHeaderBackButton({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return detailHeaderIconButton(
      icon: Symbols.arrow_back,
      tooltip: l10n.shellBack,
      semanticLabel: l10n.shellBack,
      onPressed: onBack,
      iconColor: scheme.onSurfaceVariant,
    );
  }
}

/// 详情顶栏编辑按钮。
class DetailHeaderEditButton extends StatelessWidget {
  const DetailHeaderEditButton({super.key, this.onEdit, required this.tooltip});

  final VoidCallback? onEdit;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return detailHeaderIconButton(
      icon: Symbols.edit,
      tooltip: tooltip,
      semanticLabel: tooltip,
      onPressed: onEdit,
      iconColor: scheme.onSurfaceVariant,
    );
  }
}

/// 详情顶栏更多菜单按钮。
class DetailHeaderMoreButton extends StatelessWidget {
  const DetailHeaderMoreButton({
    super.key,
    this.moreMenuEntries = const <M3EMenuNode>[],
  });

  final List<M3EMenuNode> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color iconColor = scheme.onSurfaceVariant;

    if (moreMenuEntries.isEmpty) {
      return detailHeaderIconButton(
        icon: Icons.more_vert,
        tooltip: l10n.metadataMoreActions,
        semanticLabel: l10n.metadataMoreActions,
        onPressed: null,
        iconColor: iconColor,
      );
    }

    return AnchoredMenu(
      position: M3EMenuAnchorPosition.bottomEnd,
      children: moreMenuEntries,
      anchorBuilder: (BuildContext context, VoidCallback open) {
        return detailHeaderIconButton(
          icon: Icons.more_vert,
          tooltip: l10n.metadataMoreActions,
          semanticLabel: l10n.metadataMoreActions,
          onPressed: open,
          iconColor: iconColor,
        );
      },
    );
  }
}
