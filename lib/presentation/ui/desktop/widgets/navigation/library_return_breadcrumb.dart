import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 面包屑式返回 [漫画库]（`/local`），可选展示当前页副标题。
final class LibraryReturnBreadcrumb extends StatelessWidget {
  const LibraryReturnBreadcrumb({
    super.key,
    this.trailingLabel,
    this.trailingTooltip,
  });

  final String? trailingLabel;
  final String? trailingTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final TextStyle linkStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: cs.primary,
    );
    final TextStyle trailStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: cs.textSecondary,
      letterSpacing: -0.1,
    );
    final Widget libraryLink = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/local'),
        borderRadius: BorderRadius.circular(tokens.radius.md),
        hoverColor: cs.primary.withValues(alpha: 0.08),
        splashColor: cs.primary.withValues(alpha: 0.12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.sm + 2,
            vertical: tokens.spacing.sm - 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(LucideIcons.library, size: 16, color: cs.primary),
              SizedBox(width: tokens.spacing.sm),
              Text('漫画库', style: linkStyle),
            ],
          ),
        ),
      ),
    );
    if (trailingLabel == null || trailingLabel!.isEmpty) {
      return Semantics(label: '返回漫画库', button: true, child: libraryLink);
    }
    final String trail = trailingLabel!;
    final String tip = trailingTooltip ?? trail;
    return Semantics(
      label: '返回漫画库，当前：$trail',
      child: Row(
        children: <Widget>[
          Semantics(
            label: '返回漫画库',
            button: true,
            excludeSemantics: true,
            child: libraryLink,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
            child: Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: cs.textTertiary,
            ),
          ),
          Expanded(
            child: _BreadcrumbTrailingTitle(
              text: trail,
              tooltipMessage: tip,
              style: trailStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 副标题仅在截断时用窄命中区（信息图标）展示完整 Tooltip，避免 [Expanded] 包一层 [Tooltip] 整行可触发。
class _BreadcrumbTrailingTitle extends StatelessWidget {
  const _BreadcrumbTrailingTitle({
    required this.text,
    required this.tooltipMessage,
    required this.style,
  });

  final String text;
  final String tooltipMessage;
  final TextStyle style;

  static const double _kTooltipIconSlot = 22;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter probe = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        if (!probe.didExceedMaxLines) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }
        return Row(
          children: <Widget>[
            SizedBox(
              width: math.max(0, constraints.maxWidth - _kTooltipIconSlot),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            Tooltip(
              message: tooltipMessage,
              waitDuration: const Duration(milliseconds: 400),
              showDuration: const Duration(seconds: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(LucideIcons.info, size: 14, color: cs.textTertiary),
              ),
            ),
          ],
        );
      },
    );
  }
}
