import 'package:flutter/material.dart';

import '../../l10n/design_system_localizations.dart';
import '../menu/anchored_menu.dart';
import 'detail_header_icon_button.dart';

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
    final DesignSystemLocalizations l10n = DesignSystemLocalizations.of(
      context,
    );
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color iconColor = scheme.onSurfaceVariant;

    if (moreMenuEntries.isEmpty) {
      return DetailHeaderIconButton(
        icon: Icons.more_vert,
        tooltip: l10n.moreActions,
        semanticLabel: l10n.moreActions,
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
          tooltip: l10n.moreActions,
          semanticLabel: l10n.moreActions,
          onPressed: open,
          iconColor: iconColor,
        );
      },
    );
  }
}
