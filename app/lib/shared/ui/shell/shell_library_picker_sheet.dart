import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_picker_row.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// medium- 底部导航「漫画库」：用 bottom sheet 选择当前库。
abstract final class ShellLibraryPickerSheet {
  ShellLibraryPickerSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<HomeLibraryDashboardRow> libraries,
    required String selectedLibraryId,
    required ValueChanged<String> onLibrarySelected,
  }) {
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));

    return M3EBottomSheet.show<void>(
      context,
      initialValue: M3EBottomSheetValue.collapsed,
      theme: m3e.bottomSheetTheme,
      builder: (BuildContext sheetContext) {
        return OverlayRouteScope(
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
                for (final HomeLibraryDashboardRow row in libraries)
                  ShellLibraryPickerRow(
                    row: row,
                    selected: row.libraryId == selectedLibraryId,
                    onTap: () {
                      onLibrarySelected(row.libraryId);
                      Navigator.of(sheetContext).maybePop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
