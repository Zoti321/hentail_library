import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
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
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: Md3eLibraryPageHeaderMetrics.verticalPadding,
        bottom: Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding,
      ),
      child: _Md3eSettingsPageHeaderToolbar(
        title: title,
        sizeClass: sizeClass,
        onBack: onBack,
        showBack: showBack,
      ),
    );
  }
}

class _Md3eSettingsPageHeaderToolbar extends StatelessWidget {
  const _Md3eSettingsPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
    this.onBack,
    required this.showBack,
  });

  final String? title;
  final Md3eWindowSizeClass sizeClass;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final String resolvedTitle = title ?? l10n.navSettings;

    return SizedBox(
      height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
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
              child: Text(
                resolvedTitle,
                style: type.headlineSmall.copyWith(
                  fontSize: Md3eLibraryPageHeaderMetrics.titleFontSize(
                    sizeClass,
                  ),
                  fontWeight: Md3eLibraryPageHeaderMetrics.titleFontWeight(
                    sizeClass,
                  ),
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
