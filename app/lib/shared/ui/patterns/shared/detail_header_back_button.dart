import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_header_icon_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 详情顶栏左侧返回。
class DetailHeaderBackButton extends StatelessWidget {
  const DetailHeaderBackButton({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return DetailHeaderIconButton(
      icon: Symbols.arrow_back,
      tooltip: l10n.shellBack,
      semanticLabel: l10n.shellBack,
      onPressed: onBack,
      iconColor: scheme.onSurfaceVariant,
    );
  }
}
