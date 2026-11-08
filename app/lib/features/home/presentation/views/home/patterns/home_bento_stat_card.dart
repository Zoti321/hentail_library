import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/widgets/settings/tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Kazumi 风统计块：独立底色 + 可变圆角 + M3E state layer。
///
/// 布局对齐 [HomeNavShortcutCard]：左上图标、右上跳转箭头（可点时）、
/// 左下标题 +「{数字} {单位}」副文案。
class HomeBentoStatCard extends StatefulWidget {
  const HomeBentoStatCard({
    super.key,
    required this.label,
    required this.caption,
    required this.icon,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.borderRadius,
    this.minHeight = 96,
    this.emphasis = HomeBentoStatEmphasis.standard,
    this.contentPadding,
    this.onPressed,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color backgroundColor;
  final Color onBackgroundColor;
  final BorderRadius borderRadius;
  final double minHeight;
  final HomeBentoStatEmphasis emphasis;
  final EdgeInsets? contentPadding;
  final VoidCallback? onPressed;

  @override
  State<HomeBentoStatCard> createState() => _HomeBentoStatCardState();
}

class _HomeBentoStatCardState extends State<HomeBentoStatCard> {
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
    final WindowSizeClass sizeClass = PageLayoutSpec.of(context).sizeClass;
    final EdgeInsets padding =
        widget.contentPadding ??
        HomePageMetrics.statCardContentPadding(sizeClass);

    final bool showCaption = widget.caption.trim().isNotEmpty;
    final VoidCallback? onPressed = widget.onPressed;
    final Color fg = widget.onBackgroundColor;
    final String semanticsLabel = showCaption
        ? '${widget.label}, ${widget.caption}'
        : widget.label;

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
                _IconBadge(
                  icon: widget.icon,
                  color: fg,
                  filled: widget.emphasis == HomeBentoStatEmphasis.hero,
                ),
                const Spacer(),
                if (onPressed != null)
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
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (showCaption) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    widget.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.bodySmall.copyWith(
                      color: fg.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: onPressed != null,
      container: onPressed == null,
      label: semanticsLabel,
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
              onPressed: onPressed ?? () {},
              focusable: onPressed != null,
              showFocusRing: onPressed != null,
              haptic: onPressed != null
                  ? M3EHapticFeedback.light
                  : M3EHapticFeedback.none,
              mouseCursor: onPressed != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
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

enum HomeBentoStatEmphasis { hero, standard, compact }

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.filled,
  });

  final IconData icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: color),
      );
    }
    return Icon(icon, size: 22, color: color.withValues(alpha: 0.9));
  }
}
