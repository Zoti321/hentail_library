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

/// 弹出配色方案选择 dialog（参考 Kazumi：四象限 palette + 点选即生效）。
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

class _ColorSchemePickerDialog extends StatelessWidget {
  const _ColorSchemePickerDialog({required this.selected});

  final AppColorSchemePreference selected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;

    return M3EDialog(
      title: l10n.settingsColorSchemeLabel,
      content: Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing.sm,
        runSpacing: spacing.sm,
        children: <Widget>[
          for (final AppColorSchemePreference preference
              in AppColorSchemePreference.values)
            _ColorSchemeOption(
              preference: preference,
              label: l10n.colorSchemePreferenceLabel(preference),
              selected: preference == selected,
              onTap: () => Navigator.of(context).pop(preference),
            ),
        ],
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.xs,
            vertical: theme.spacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                style: theme.typeScale.labelMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kazumi `PaletteCard` 同构：由 seed 派生三色四象限预览 + 选中勾。
///
/// 必须在固定尺寸内用 [StackFit.expand] 给 [Column]/[Expanded] 有界高度，
/// 否则 Card 按 intrinsic 收缩、色块高度为 0（只剩空白卡片底）。
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
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Material(
            color: scheme.surfaceContainerHighest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(10),
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
                  color: scheme.surfaceContainerLow,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
