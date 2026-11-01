import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_title.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Settings sticky toolbar: back + title (category title on narrow detail).
class Md3eSettingsPageHeader extends StatelessWidget {
  const Md3eSettingsPageHeader({
    super.key,
    this.title,
    this.onBack,
    this.showBack = true,
  });

  final String? title;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.headerVerticalInset),
      child: _Md3eSettingsPageHeaderToolbar(
        title: title,
        onBack: onBack,
        showBack: showBack,
      ),
    );
  }
}

class _Md3eSettingsPageHeaderToolbar extends StatelessWidget {
  const _Md3eSettingsPageHeaderToolbar({
    required this.title,
    this.onBack,
    required this.showBack,
  });

  final String? title;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final String resolvedTitle = title ?? l10n.navSettings;

    return SizedBox(
      height: Md3ePageLayoutSpec.toolbarRowHeight,
      child: Row(
        children: <Widget>[
          if (showBack)
            M3EIconButton(
              icon: Icon(
                Symbols.arrow_back,
                size: Md3eLibraryPageHeaderMetrics.actionIconSize,
                color: scheme.onSurfaceVariant,
              ),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.shellBack,
              semanticLabel: l10n.shellBack,
              onPressed: onBack,
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Md3ePageTitle(resolvedTitle),
            ),
          ),
        ],
      ),
    );
  }
}
