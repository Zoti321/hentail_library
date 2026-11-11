import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Kazumo 风导航块：左上功能图标、右上跳转箭头、左下标题 + 简短副文案。
class HomeNavShortcutCard extends StatefulWidget {
  const HomeNavShortcutCard({
    super.key,
    required this.title,
    required this.caption,
    required this.icon,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.borderRadius,
    required this.onPressed,
    this.minHeight = 104,
  });

  final String title;
  final String caption;
  final IconData icon;
  final Color backgroundColor;
  final Color onBackgroundColor;
  final BorderRadius borderRadius;
  final VoidCallback onPressed;
  final double minHeight;

  @override
  State<HomeNavShortcutCard> createState() => _HomeNavShortcutCardState();
}

class _HomeNavShortcutCardState extends State<HomeNavShortcutCard> {
  bool _pressed = false;

  BorderRadius get _motionRadius => _pressed
      ? BorderRadius.circular(kTonalSurfaceRadius)
      : widget.borderRadius;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETypeScale type = theme.typeScale;
    final M3ECardTheme cardTheme = theme.cardTheme.copyWith(
      stateLayerColor: widget.onBackgroundColor,
    );
    final bool reduceMotion = LabMotion.reduceMotionOf(context);
    final EdgeInsets padding = HomePageMetrics.statCardContentPadding(
      PageLayoutSpec.of(context).sizeClass,
    );
    final Color fg = widget.onBackgroundColor;
    final Color captionColor = fg.withValues(alpha: 0.72);

    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(widget.icon, size: 24, color: fg.withValues(alpha: 0.92)),
                const Spacer(),
                Icon(
                  Symbols.arrow_forward,
                  size: 20,
                  color: fg.withValues(alpha: 0.55),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: captionColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      label: '${widget.title}, ${widget.caption}',
      excludeSemantics: true,
      child: M3ECardRadiusMotion(
        radius: _motionRadius,
        snap: reduceMotion,
        builder: (BuildContext context, BorderRadius animatedRadius) {
          return M3ETheme(
            data: theme.copyWith(cardTheme: cardTheme),
            child: M3ECard(
              variant: M3ECardVariant.filled,
              color: widget.backgroundColor,
              borderRadius: animatedRadius,
              elevation: M3EElevation.level0,
              onPressed: widget.onPressed,
              focusable: true,
              showFocusRing: true,
              haptic: M3EHapticFeedback.light,
              mouseCursor: SystemMouseCursors.click,
              padding: EdgeInsets.zero,
              onStateChanged: (M3EInteractionState state) {
                final bool next = state.pressed;
                if (_pressed != next) {
                  setState(() => _pressed = next);
                }
              },
              child: content,
            ),
          );
        },
      ),
    );
  }
}
