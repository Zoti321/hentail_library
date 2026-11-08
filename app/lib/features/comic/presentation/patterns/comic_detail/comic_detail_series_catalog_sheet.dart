import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// medium- 漫画详情「系列目录」：bottom sheet 选卷。
abstract final class ComicDetailSeriesCatalogSheet {
  ComicDetailSeriesCatalogSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<String> catalog,
    required int currentIndex,
    required ValueChanged<int> onSelectIndex,
  }) {
    final AppLocalizations l10n = context.l10n;
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
    final String title = l10n.comicDetailSeriesCatalog;

    return M3EBottomSheet.show<void>(
      context,
      initialValue: M3EBottomSheetValue.collapsed,
      theme: m3e.bottomSheetTheme,
      builder: (BuildContext sheetContext) {
        final double itemGap = m3e.menuTheme.itemGap;
        return overlayRouteScope(
          scope: scope,
          child: M3ETheme(
            data: m3e,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                m3e.spacing.md,
                m3e.spacing.sm,
                m3e.spacing.md,
                m3e.spacing.lg,
              ),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: m3e.spacing.md),
                  child: Text(title, style: m3e.typeScale.titleLarge),
                ),
                for (int i = 0; i < catalog.length; i++) ...<Widget>[
                  if (i > 0 && itemGap > 0) SizedBox(height: itemGap),
                  M3EMenuItem(
                    label: catalog[i],
                    leading: const Icon(Symbols.menu_book),
                    selected: i == currentIndex,
                    onTap: () {
                      onSelectIndex(i);
                      Navigator.of(sheetContext).maybePop();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
