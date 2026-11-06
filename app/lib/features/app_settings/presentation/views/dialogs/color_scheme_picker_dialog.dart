import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/domain/app_color_scheme_preference.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/theme/color/app_color_scheme_seeds.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

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
  final M3EThemeData m3e = withAppFontFamily(scope.m3e);
  return M3EDialog.show<AppColorSchemePreference>(
    context,
    dialog: overlayRouteScope(
      scope: scope.withM3e(m3e),
      child: _ColorSchemePickerDialog(selected: selected),
    ),
  );
}

/// 配色选项瓦片度量（对齐 Kazumi PaletteCard 70² + 文案列宽）。
abstract final class _PaletteMetrics {
  static const double cardSize = 70;
  static const double cardInset = 10;
  static const double tileMinWidth = 76;
  static const double tileHeight = 108;
  static const double gap = 8;

  /// 按内容区宽度计算列数，保证格子等宽、左右边距由 dialog padding 对称承担。
  static int columnsFor(double maxWidth) {
    final int columns = ((maxWidth + gap) / (tileMinWidth + gap)).floor();
    return columns.clamp(3, AppColorSchemePreference.values.length);
  }
}

class _ColorSchemePickerDialog extends StatelessWidget {
  const _ColorSchemePickerDialog({required this.selected});

  final AppColorSchemePreference selected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final List<AppColorSchemePreference> preferences =
        AppColorSchemePreference.values;

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
          final int columns = _PaletteMetrics.columnsFor(constraints.maxWidth);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: preferences.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _PaletteMetrics.gap,
              crossAxisSpacing: _PaletteMetrics.gap,
              mainAxisExtent: _PaletteMetrics.tileHeight,
            ),
            itemBuilder: (BuildContext context, int index) {
              final AppColorSchemePreference preference = preferences[index];
              return _ColorSchemeOption(
                preference: preference,
                label: l10n.colorSchemePreferenceLabel(preference),
                selected: preference == selected,
                onTap: () => Navigator.of(context).pop(preference),
              );
            },
          );
        },
      ),
    );
  }
}

class _ColorSchemeOption extends StatelessWidget {
  const _ColorSchemeOption({
    required this.preference,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppColorSchemePreference preference;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _PaletteCard(
              color: colorSchemeSeedForId(
                colorSchemeIdForPreference(preference),
              ),
              selected: selected,
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typeScale.labelMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 对齐 Kazumi `PaletteCard`：默认 [Card]（不覆盖 color）+ HCT 三色圆 + 选中勾。
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Hct hct = Hct.fromInt(color.toARGB32());
    final Color primary = Color(Hct.from(hct.hue, 20.0, 90.0).toInt());
    final Color tertiary = Color(Hct.from(hct.hue + 50, 20.0, 85.0).toInt());
    final Color primaryContainer = Color(Hct.from(hct.hue, 30.0, 50.0).toInt());
    final Color checkbox = Color(Hct.from(hct.hue, 30.0, 40.0).toInt());

    return SizedBox(
      width: _PaletteMetrics.cardSize,
      height: _PaletteMetrics.cardSize,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 与 Kazumi 相同：elevation: 0、不设 color → M3 默认 surfaceContainerLow。
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(_PaletteMetrics.cardInset),
              child: ClipOval(
                child: Column(
                  children: <Widget>[
                    Expanded(child: ColoredBox(color: primary)),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(child: ColoredBox(color: tertiary)),
                          Expanded(child: ColoredBox(color: primaryContainer)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selected)
            Center(
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: checkbox,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
