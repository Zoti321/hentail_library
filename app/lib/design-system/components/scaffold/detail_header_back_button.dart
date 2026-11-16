import 'package:flutter/material.dart';

import '../../l10n/design_system_localizations.dart';
import 'detail_header_icon_button.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 详情顶栏左侧返回。
class DetailHeaderBackButton extends StatelessWidget {
  const DetailHeaderBackButton({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final DesignSystemLocalizations l10n = DesignSystemLocalizations.of(
      context,
    );
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return DetailHeaderIconButton(
      icon: Symbols.arrow_back,
      tooltip: l10n.backLabel,
      semanticLabel: l10n.backLabel,
      onPressed: onBack,
      iconColor: scheme.onSurfaceVariant,
    );
  }
}
