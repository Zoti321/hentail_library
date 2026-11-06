import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/domain/app_color_scheme_preference.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/theme/color/app_color_scheme_seeds.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 弹出配色方案选择 dialog（参考 Kazumi：圆形三色调 palette + 点选即生效）。
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
        borderRadius: BorderRadius.circular(36),
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

/// 正圆三色调预览（上半 / 左下 / 右下），对齐 Kazumi PaletteCard 分区。
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.color, required this.selected});

  static const double _size = 56;

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: color);
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size.square(_size),
            painter: _ThreeToneCirclePainter(
              top: scheme.primaryContainer,
              bottomLeft: scheme.tertiaryContainer,
              bottomRight: scheme.primary,
            ),
          ),
          if (selected)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: scheme.onPrimary,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThreeToneCirclePainter extends CustomPainter {
  const _ThreeToneCirclePainter({
    required this.top,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Color top;
  final Color bottomLeft;
  final Color bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;
    final Rect oval = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(oval));

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // 上半圆
    paint.color = top;
    canvas.drawArc(oval, math.pi, math.pi, true, paint);

    // 左下
    paint.color = bottomLeft;
    canvas.drawArc(oval, math.pi / 2, math.pi / 2, true, paint);

    // 右下
    paint.color = bottomRight;
    canvas.drawArc(oval, 0, math.pi / 2, true, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThreeToneCirclePainter oldDelegate) {
    return top != oldDelegate.top ||
        bottomLeft != oldDelegate.bottomLeft ||
        bottomRight != oldDelegate.bottomRight;
  }
}
