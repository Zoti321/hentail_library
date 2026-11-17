import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Empty adaptive filter/sort shell for Image set browse (no logic this slice).
///
/// compact / medium → [M3EBottomSheet]; expanded+ → [M3ESideSheet].
/// Does not use Comic [LibraryFilterSortSheet] / facade.
abstract final class ImageSetLibraryFilterSheet {
  ImageSetLibraryFilterSheet._();

  static Future<void> show(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final AppLocalizations l10n = context.l10n;
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
    final String title = l10n.libraryFilterSortTooltip;
    final Widget body = OverlayRouteScope(
      scope: scope,
      child: M3ETheme(
        data: m3e,
        child: const SizedBox.shrink(
          key: ValueKey<String>('imageSetFilterSortEmptyBody'),
        ),
      ),
    );

    if (libraryFilterSortPrefersBottomSheetForViewport(viewportWidth)) {
      return M3EBottomSheet.show<void>(
        context,
        useRootNavigator: true,
        expandToFullScreen: true,
        initialValue: M3EBottomSheetValue.fullScreen,
        fullScreenTitle: title,
        theme: m3e.bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return PrimaryScrollController.none(
            child: SingleChildScrollView(child: body),
          );
        },
      );
    }

    return M3ESideSheet.show<void>(
      context,
      title: title,
      width: libraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: libraryFilterSortSideSheetDetachedForViewport(viewportWidth),
      theme: libraryFilterSortSideSheetTheme(m3e),
      scrollable: true,
      useRootNavigator: true,
      body: body,
    );
  }
}
