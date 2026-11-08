import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/widgets/settings/tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页 bento 统计卡布局。
enum HomeBentoStatLayout {
  /// 原样式：右上标签文案 + 中间大数字 + 底部 caption。
  metric,

  /// 管理入口：右上箭头 + 标题 +「{数字} {单位}」（对齐 [HomeNavShortcutCard]）。
  shortcut,
}

/// Kazumi 风统计块：独立底色 + 可变圆角 + M3E state layer。
class HomeBentoStatCard extends StatefulWidget {
  const HomeBentoStatCard({
    super.key,
    required this.label,
    required this.caption,
    required this.icon,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.borderRadius,
    this.valueText = '',
    this.minHeight = 96,
    this.emphasis = HomeBentoStatEmphasis.standard,
    this.layout = HomeBentoStatLayout.metric,
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
  final HomeBentoStatEmphasis emphasis;
  final HomeBentoStatLayout layout;
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
    final VoidCallback? onPressed = widget.onPressed;

    final Widget content = switch (widget.layout) {
      HomeBentoStatLayout.metric => _MetricBody(
        label: widget.label,
        valueText: widget.valueText,
        caption: widget.caption,
        icon: widget.icon,
        onBackgroundColor: widget.onBackgroundColor,
        minHeight: widget.minHeight,
        emphasis: widget.emphasis,
        padding: padding,
        type: type,
      ),
      HomeBentoStatLayout.shortcut => _ShortcutBody(
        label: widget.label,
        caption: widget.caption,
        icon: widget.icon,
        onBackgroundColor: widget.onBackgroundColor,
        minHeight: widget.minHeight,
        emphasis: widget.emphasis,
        padding: padding,
        type: type,
        showTrailingArrow: onPressed != null,
      ),
    };

    final bool showValue = widget.valueText.trim().isNotEmpty;
    final bool showCaption = widget.caption.trim().isNotEmpty;
    final String semanticsLabel = switch ((showValue, showCaption)) {
      (true, true) => '${widget.label}, ${widget.valueText}, ${widget.caption}',
      (true, false) => '${widget.label}, ${widget.valueText}',
      (false, true) => '${widget.label}, ${widget.caption}',
      (false, false) => widget.label,
    };

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

class _MetricBody extends StatelessWidget {
  const _MetricBody({
    required this.label,
    required this.valueText,
    required this.caption,
    required this.icon,
    required this.onBackgroundColor,
    required this.minHeight,
    required this.emphasis,
    required this.padding,
    required this.type,
  });

  final String label;
  final String valueText;
  final String caption;
  final IconData icon;
  final Color onBackgroundColor;
  final double minHeight;
  final HomeBentoStatEmphasis emphasis;
  final EdgeInsets padding;
  final M3ETypeScale type;

  @override
  Widget build(BuildContext context) {
    final double valueSize = switch (emphasis) {
      HomeBentoStatEmphasis.hero => 36,
      HomeBentoStatEmphasis.standard => 28,
      HomeBentoStatEmphasis.compact => 24,
    };
    final bool showValue = valueText.trim().isNotEmpty;
    final bool showCaption = caption.trim().isNotEmpty;
    final bool compactHeaderOnly = !showValue && !showCaption;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
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
                  icon: icon,
                  color: onBackgroundColor,
                  filled:
                      emphasis == HomeBentoStatEmphasis.hero ||
                      compactHeaderOnly,
                ),
                const Spacer(),
                Text(
                  label,
                  style: type.labelLarge.copyWith(
                    color: onBackgroundColor.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
            if (showValue) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                valueText,
                style: type.headlineLarge.copyWith(
                  fontSize: valueSize,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                  color: onBackgroundColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
            ] else if (!compactHeaderOnly)
              const SizedBox(height: 12),
            if (showCaption)
              Text(
                caption,
                maxLines: showValue ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: (showValue ? type.bodySmall : type.titleMedium).copyWith(
                  color: showValue
                      ? onBackgroundColor.withValues(alpha: 0.72)
                      : onBackgroundColor.withValues(alpha: 0.92),
                  height: showValue ? null : 1.25,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutBody extends StatelessWidget {
  const _ShortcutBody({
    required this.label,
    required this.caption,
    required this.icon,
    required this.onBackgroundColor,
    required this.minHeight,
    required this.emphasis,
    required this.padding,
    required this.type,
    required this.showTrailingArrow,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color onBackgroundColor;
  final double minHeight;
  final HomeBentoStatEmphasis emphasis;
  final EdgeInsets padding;
  final M3ETypeScale type;
  final bool showTrailingArrow;

  @override
  Widget build(BuildContext context) {
    final Color fg = onBackgroundColor;
    final bool showCaption = caption.trim().isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                _IconBadge(
                  icon: icon,
                  color: fg,
                  filled: emphasis == HomeBentoStatEmphasis.hero,
                ),
                const Spacer(),
                if (showTrailingArrow)
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
                  label,
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
                    caption,
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
  }
}

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
