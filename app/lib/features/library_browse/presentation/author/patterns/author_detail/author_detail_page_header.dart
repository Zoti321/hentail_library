import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/components/scaffold/pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 作者资料顶栏：仅返回（重命名与链接编辑在正文原位进行）。
class AuthorDetailPageHeader extends StatelessWidget {
  const AuthorDetailPageHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color iconColor = scheme.onSurfaceVariant;
    const double iconSize = 20;

    return PinnedToolbarChrome(
      child: Align(
        alignment: Alignment.centerLeft,
        child: M3EIconButton(
          icon: Icon(Symbols.arrow_back, size: iconSize, color: iconColor),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: context.l10n.shellBack,
          semanticLabel: context.l10n.shellBack,
          onPressed: onBack,
        ),
      ),
    );
  }
}
