import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
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

    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                _IconBadge(
                  icon: widget.icon,
                  color: widget.onBackgroundColor,
                  filled: widget.emphasis == Md3eHomeBentoStatEmphasis.hero,
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
            Text(
              widget.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.bodySmall.copyWith(
                color: widget.onBackgroundColor.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      label: '${widget.label}, ${widget.valueText}, ${widget.caption}',
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
              onPressed: () {},
              focusable: false,
              showFocusRing: false,
              haptic: M3EHapticFeedback.none,
              mouseCursor: SystemMouseCursors.basic,
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
