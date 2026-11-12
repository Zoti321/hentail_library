import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_header_icon_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
      return DetailHeaderIconButton(
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
        return DetailHeaderIconButton(
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
