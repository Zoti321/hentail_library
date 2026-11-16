import 'package:flutter/material.dart';

import '../../l10n/design_system_localizations.dart';
import 'library_page_header_metrics.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// MD3E 页头工具行左侧返回（与 [SettingsPageHeader] 一致）。
class PageHeaderBackButton extends StatelessWidget {
  const PageHeaderBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final DesignSystemLocalizations l10n = DesignSystemLocalizations.of(
      context,
    );
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return M3EIconButton(
      icon: Icon(
        Symbols.arrow_back,
        size: LibraryPageHeaderMetrics.actionIconSize,
        color: scheme.onSurfaceVariant,
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: l10n.backLabel,
      semanticLabel: l10n.backLabel,
      onPressed: onPressed,
    );
  }
}
