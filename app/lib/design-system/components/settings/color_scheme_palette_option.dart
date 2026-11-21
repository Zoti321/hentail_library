import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../motion/motion.dart';

/// Selectable color-scheme swatch: HCT tri-tone circle + label + MD3e card states.
///
/// Interaction (state layer + press shape morph) is limited to the card; the
/// label below is not part of the hit / morph surface. Hosts supply [seed] /
/// [label]; this widget does not read app preferences or ARB.
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

  /// Resting card corners (soft squircle).
  static const double restRadius = 16;

  /// Pressed card corners (M3e shape morph → tighter square).
  static const double pressedRadius = 8;

  final Color seed;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _PaletteCard(
            seed: seed,
            selected: selected,
            onTap: onTap,
            semanticLabel: label,
          ),
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
  }
}

/// Card-only interactive surface: state layer + press radius morph.
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.seed,
    required this.selected,
    required this.semanticLabel,
    this.onTap,
  });

  final Color seed;
  final bool selected;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETabTheme tabTheme = theme.tabTheme;
    final bool reduceMotion = LabMotion.reduceMotionOf(context);

    return M3ETappable(
      onTap: onTap,
      enabled: onTap != null,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, M3EInteractionState state) {
        final BorderRadius targetRadius = BorderRadius.all(
          Radius.circular(
            state.pressed
                ? ColorSchemePaletteOption.pressedRadius
                : ColorSchemePaletteOption.restRadius,
          ),
        );
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

        return M3ECardRadiusMotion(
          radius: targetRadius,
          snap: reduceMotion,
          builder: (BuildContext context, BorderRadius animatedRadius) {
            return _PaletteSwatch(
              seed: seed,
              selected: selected,
              borderRadius: animatedRadius,
              overlay: stateAlpha > 0
                  ? stateColor.withValues(alpha: stateAlpha)
                  : null,
            );
          },
        );
      },
    );
  }
}

/// HCT tri-tone circle on a filled card; selection check overlays the center.
///
/// Must use [Container] (decorated, no child) rather than [ColoredBox]: the
/// latter collapses under [Expanded] loose constraints.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.seed,
    required this.selected,
    required this.borderRadius,
    this.overlay,
  });

  final Color seed;
  final bool selected;
  final BorderRadius borderRadius;
  final Color? overlay;

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
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: surfaceContainerLow),
            Padding(
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
            if (overlay != null)
              Positioned.fill(child: ColoredBox(color: overlay!)),
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
      ),
    );
  }
}
