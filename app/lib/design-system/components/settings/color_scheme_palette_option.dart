import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../motion/effects_decorated_box.dart';

/// Selectable color-scheme swatch: HCT tri-tone circle + label + MD3e state layer.
///
/// Hosts supply [seed] / [label]; this widget does not read app preferences or ARB.
class ColorSchemePaletteOption extends StatelessWidget {
  const ColorSchemePaletteOption({
    super.key,
    required this.seed,
    required this.label,
    required this.selected,
    this.onTap,
  });

  static const double cardSize = 70;
  static const double cardInset = 10;
  static const double tileMinWidth = 76;
  static const double tileHeight = 108;
  static const double gap = 8;
  static const BorderRadius _tileRadius = BorderRadius.all(Radius.circular(16));

  final Color seed;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETabTheme tabTheme = theme.tabTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: M3ETappable(
        onTap: onTap,
        enabled: onTap != null,
        semanticLabel: label,
        builder: (BuildContext context, M3EInteractionState state) {
          final double stateAlpha = tabTheme.stateOpacity(
            hovered: state.hovered,
            focused: state.focused,
            pressed: state.pressed,
          );
          final Color stateColor = tabTheme.stateLayerColor(
            scheme,
            variant: M3ETabsVariant.primary,
            selected: selected,
          );
          final Color? overlay = stateAlpha > 0
              ? stateColor.withValues(alpha: stateAlpha)
              : null;

          return EffectsDecoratedBox(
            decoration: BoxDecoration(
              color: overlay,
              borderRadius: _tileRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _PaletteSwatch(seed: seed, selected: selected),
                SizedBox(height: theme.spacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.typeScale.labelMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// HCT tri-tone circle on a filled card; selection check overlays the center.
///
/// Must use [Container] (decorated, no child) rather than [ColoredBox]: the
/// latter collapses under [Expanded] loose constraints.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.seed, required this.selected});

  final Color seed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Hct hct = Hct.fromInt(seed.toARGB32());
    final Color primary = Color(Hct.from(hct.hue, 20.0, 90.0).toInt());
    final Color tertiary = Color(Hct.from(hct.hue + 50, 20.0, 85.0).toInt());
    final Color primaryContainer = Color(Hct.from(hct.hue, 30.0, 50.0).toInt());
    final Color checkbox = Color(Hct.from(hct.hue, 30.0, 40.0).toInt());
    final Color surfaceContainerLow =
        M3ETheme.of(context).colorScheme.surfaceContainerLow;

    return SizedBox(
      width: ColorSchemePaletteOption.cardSize,
      height: ColorSchemePaletteOption.cardSize,
      child: Stack(
        children: <Widget>[
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(ColorSchemePaletteOption.cardInset),
              child: ClipOval(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(child: Container(color: primary)),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(child: Container(color: tertiary)),
                          Expanded(child: Container(color: primaryContainer)),
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
                  color: surfaceContainerLow,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
