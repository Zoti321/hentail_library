import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页下钻的二级页（阅读历史、垃圾桶等）：能 pop 则 pop，否则回 `/home`。
void md3ePopOrGoHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/home');
}

/// MD3E 页头工具行左侧返回（与 [Md3eSettingsPageHeader] 一致）。
class Md3ePageHeaderBackButton extends StatelessWidget {
  const Md3ePageHeaderBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return M3EIconButton(
      icon: Icon(
        Symbols.arrow_back,
        size: Md3eLibraryPageHeaderMetrics.actionIconSize,
        color: scheme.onSurfaceVariant,
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: l10n.shellBack,
      semanticLabel: l10n.shellBack,
      onPressed: onPressed,
    );
  }
}
