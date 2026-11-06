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

/// Kazumi `PaletteCard`：圆角矩形容器 + 内嵌圆形三色调 + 选中勾。
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: color);
    final M3EColorScheme m3e = M3ETheme.of(context).colorScheme;
    const double circleSize =
        _PaletteMetrics.cardSize - 2 * _PaletteMetrics.cardInset;

    return SizedBox(
      width: _PaletteMetrics.cardSize,
      height: _PaletteMetrics.cardSize,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Material(
            color: m3e.surfaceContainerHighest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(_PaletteMetrics.cardInset),
              child: CustomPaint(
                size: const Size.square(circleSize),
                painter: _ThreeToneCirclePainter(
                  top: scheme.primaryContainer,
                  bottomLeft: scheme.tertiaryContainer,
                  bottomRight: scheme.primary,
                ),
              ),
            ),
          ),
          if (selected)
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: scheme.onPrimary,
                size: 12,
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

    paint.color = top;
    canvas.drawArc(oval, math.pi, math.pi, true, paint);

    paint.color = bottomLeft;
    canvas.drawArc(oval, math.pi / 2, math.pi / 2, true, paint);

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
