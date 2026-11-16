import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读活动统计胶囊：顶栏标题 + 左右指标 + 中间星芒分隔（对齐 Kazumi「观看统计」）。
class HomeActivityStatsCapsule extends StatelessWidget {
  const HomeActivityStatsCapsule({
    super.key,
    required this.title,
    required this.leftValue,
    required this.leftLabel,
    required this.rightValue,
    required this.rightLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.mutedForegroundColor,
  });

  final String title;
  final String leftValue;
  final String leftLabel;
  final String rightValue;
  final String rightLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? mutedForegroundColor;

  /// 浅灰绿底，贴近参考「观看统计」胶囊。
  static const Color lightBackground = Color(0xFFE9EDEC);

  /// 星芒点缀色（深青绿）。
  static const Color sparkleColor = Color(0xFF1B4D3E);

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final Brightness brightness = Theme.of(context).brightness;

    final Color bg =
        backgroundColor ??
        (brightness == Brightness.dark
            ? scheme.surfaceContainerHigh
            : lightBackground);
    final Color fg = foregroundColor ?? scheme.onSurface;
    final Color muted =
        mutedForegroundColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.78);

    final String semanticsLabel =
        '$title, $leftLabel $leftValue, $rightLabel $rightValue';

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: type.labelLarge.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricColumn(
                      value: leftValue,
                      label: leftLabel,
                      foreground: fg,
                      muted: muted,
                      type: type,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _SparkleCluster(
                      color: brightness == Brightness.dark
                          ? scheme.primary
                          : sparkleColor,
                    ),
                  ),
                  Expanded(
                    child: _MetricColumn(
                      value: rightValue,
                      label: rightLabel,
                      foreground: fg,
                      muted: muted,
                      type: type,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.value,
    required this.label,
    required this.foreground,
    required this.muted,
    required this.type,
  });

  final String value;
  final String label;
  final Color foreground;
  final Color muted;
  final M3ETypeScale type;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.headlineLarge.copyWith(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: foreground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.bodySmall.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _SparkleCluster extends StatelessWidget {
  const _SparkleCluster({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 2,
            top: 10,
            child: Icon(Symbols.auto_awesome, size: 14, color: color),
          ),
          Positioned(
            right: 0,
            top: 4,
            child: Icon(Symbols.auto_awesome, size: 18, color: color),
          ),
          Positioned(
            right: 8,
            bottom: 2,
            child: Icon(Symbols.auto_awesome, size: 11, color: color),
          ),
        ],
      ),
    );
  }
}
