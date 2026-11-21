import 'package:flutter/material.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/domain/app_color_scheme_preference.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/app_settings/presentation/l10n/app_settings_l10n.dart';

/// 弹出配色方案选择 dialog（参考 Kazumi：圆角卡 + 圆形三色调 + 点选即生效）。
///
/// 使用 [M3EDialog.show]（`rootNavigator: true`），scrim 覆盖整窗含导航轨。
Future<AppColorSchemePreference?> showColorSchemePickerDialog({
  required BuildContext context,
  required AppColorSchemePreference selected,
}) {
  final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
    context,
  );
  final M3EThemeData base = withAppFontFamily(scope.m3e);
  // 配色弹窗用偏白的 surfaceContainerLow，与壳层 surface 画布区分。
  final M3EThemeData m3e = base.copyWith(
    dialogTheme: base.dialogTheme.copyWith(
      appearance: base.dialogTheme.appearance.copyWith(
        containerColor: base.colorScheme.surfaceContainerLow,
      ),
    ),
  );
  return M3EDialog.show<AppColorSchemePreference>(
    context,
    dialog: OverlayRouteScope(
      scope: scope.withM3e(m3e),
      child: _ColorSchemePickerDialog(selected: selected),
    ),
  );
}

class _ColorSchemePickerDialog extends StatelessWidget {
  const _ColorSchemePickerDialog({required this.selected});

  final AppColorSchemePreference selected;

  static int _columnsFor(double maxWidth) {
    final int columns =
        ((maxWidth + ColorSchemePaletteOption.gap) /
                (ColorSchemePaletteOption.tileMinWidth +
                    ColorSchemePaletteOption.gap))
            .floor();
    return columns.clamp(3, kColorSchemePickerOrder.length);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    // 色相环顺序；`violet` 与 brand 同色，仅展示 brand（文案为紫罗兰色）。
    final List<AppColorSchemePreference> preferences = kColorSchemePickerOrder;
    final AppColorSchemePreference effectiveSelected =
        selected == AppColorSchemePreference.violet
        ? AppColorSchemePreference.brand
        : selected;

    return M3EDialog(
      title: l10n.settingsColorSchemeLabel,
      // 左右对称；避免默认 content padding 与 Wrap 居中叠出视觉偏斜。
      contentPadding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.sm,
        spacing.lg,
        spacing.lg,
      ),
      content: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = _columnsFor(constraints.maxWidth);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: preferences.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: ColorSchemePaletteOption.gap,
              crossAxisSpacing: ColorSchemePaletteOption.gap,
              mainAxisExtent: ColorSchemePaletteOption.tileHeight,
            ),
            itemBuilder: (BuildContext context, int index) {
              final AppColorSchemePreference preference = preferences[index];
              return ColorSchemePaletteOption(
                seed: colorSchemeSeedForId(
                  colorSchemeIdForPreference(preference),
                ),
                label: l10n.colorSchemePreferenceLabel(preference),
                selected: preference == effectiveSelected,
                onTap: () => Navigator.of(context).pop(preference),
              );
            },
          );
        },
      ),
    );
  }
}
