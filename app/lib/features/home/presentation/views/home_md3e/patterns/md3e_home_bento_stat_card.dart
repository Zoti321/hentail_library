import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page_metrics.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/widgets/settings/tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Kazumi 风统计块：独立底色 + 可变圆角 + M3E state layer（无业务动作）。
class Md3eHomeBentoStatCard extends StatefulWidget {
  const Md3eHomeBentoStatCard({
    super.key,
    required this.label,
    required this.valueText,
    required this.caption,
    required this.icon,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.borderRadius,
    this.minHeight = 96,
    this.emphasis = Md3eHomeBentoStatEmphasis.standard,
    this.contentPadding,
    this.onPressed,
  });

  final String label;
  final String valueText;
  final String caption;
  final IconData icon;
  final Color backgroundColor;
  final Color onBackgroundColor;
  final BorderRadius borderRadius;
  final double minHeight;
  final Md3eHomeBentoStatEmphasis emphasis;
  final EdgeInsets? contentPadding;
  final VoidCallback? onPressed;

  @override
  State<Md3eHomeBentoStatCard> createState() => _Md3eHomeBentoStatCardState();
}

class _Md3eHomeBentoStatCardState extends State<Md3eHomeBentoStatCard> {
  bool _pressed = false;

  BorderRadius get _motionRadius => _pressed
      ? BorderRadius.circular(kMd3eTonalSurfaceRadius)
      : widget.borderRadius;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETypeScale type = theme.typeScale;
    final M3ECardTheme cardTheme = theme.cardTheme.copyWith(
      stateLayerColor: widget.onBackgroundColor,
    );
    final double valueSize = switch (widget.emphasis) {
      Md3eHomeBentoStatEmphasis.hero => 36,
      Md3eHomeBentoStatEmphasis.standard => 28,
      Md3eHomeBentoStatEmphasis.compact => 24,
    };
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Md3eWindowSizeClass sizeClass = Md3ePageLayoutSpec.of(context)
        .sizeClass;
    final EdgeInsets padding =
        widget.contentPadding ??
        Md3eHomePageMetrics.statCardContentPadding(sizeClass);

    final bool showValue = widget.valueText.trim().isNotEmpty;
    final bool showCaption = widget.caption.trim().isNotEmpty;
    final bool compactHeaderOnly = !showValue && !showCaption;
    final VoidCallback? onPressed = widget.onPressed;
    final String semanticsLabel = switch ((showValue, showCaption)) {
      (true, true) => '${widget.label}, ${widget.valueText}, ${widget.caption}',
      (true, false) => '${widget.label}, ${widget.valueText}',
      (false, true) => '${widget.label}, ${widget.caption}',
      (false, false) => widget.label,
    };

    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: compactHeaderOnly
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                _IconBadge(
                  icon: widget.icon,
                  color: widget.onBackgroundColor,
                  filled:
                      widget.emphasis == Md3eHomeBentoStatEmphasis.hero ||
                      compactHeaderOnly,
                ),
                const Spacer(),
                Text(
                  widget.label,
                  style: type.labelLarge.copyWith(
                    color: widget.onBackgroundColor.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
            if (showValue) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                widget.valueText,
                style: type.headlineLarge.copyWith(
                  fontSize: valueSize,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                  color: widget.onBackgroundColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
            ] else if (!compactHeaderOnly)
              const SizedBox(height: 12),
            if (showCaption)
              Text(
                widget.caption,
                maxLines: showValue ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: (showValue ? type.bodySmall : type.titleMedium)
                    .copyWith(
                      color: showValue
                          ? widget.onBackgroundColor.withValues(alpha: 0.72)
                          : widget.onBackgroundColor.withValues(alpha: 0.92),
                      height: showValue ? null : 1.25,
                    ),
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

enum Md3eHomeBentoStatEmphasis { hero, standard, compact }

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
