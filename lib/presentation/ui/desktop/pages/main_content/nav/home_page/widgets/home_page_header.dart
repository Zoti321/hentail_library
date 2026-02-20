import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

TextStyle _buildDesktopPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    color: colorScheme.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({
    super.key,
    required this.title,
    required this.greetingText,
    required this.onRefresh,
    required this.onAutoDetectContentRating,
    required this.onScan,
  });

  final String title;
  final String greetingText;
  final VoidCallback onRefresh;
  final VoidCallback onAutoDetectContentRating;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        _HomeHeaderTextBlock(
          title: title,
          greetingText: greetingText,
          colorScheme: colorScheme,
          tokens: tokens,
        ),
        _HomeHeaderActionBlock(
          colorScheme: colorScheme,
          onRefresh: onRefresh,
          onAutoDetectContentRating: onAutoDetectContentRating,
          onScan: onScan,
        ),
      ],
    );
  }
}

class _HomeHeaderTextBlock extends StatelessWidget {
  const _HomeHeaderTextBlock({
    required this.title,
    required this.greetingText,
    required this.colorScheme,
    required this.tokens,
  });

  final String title;
  final String greetingText;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: _buildDesktopPageTitleStyle(colorScheme)),
        SizedBox(height: tokens.spacing.xs),
        Text(
          greetingText,
          style: TextStyle(color: colorScheme.textTertiary, fontSize: 13),
        ),
      ],
    );
  }
}

class _HomeHeaderActionBlock extends StatelessWidget {
  const _HomeHeaderActionBlock({
    required this.colorScheme,
    required this.onRefresh,
    required this.onAutoDetectContentRating,
    required this.onScan,
  });

  final ColorScheme colorScheme;
  final VoidCallback onRefresh;
  final VoidCallback onAutoDetectContentRating;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.refreshCw,
          tooltip: '',
          semanticLabel: '刷新漫画库列表',
          iconSize: 16,
          size: 24,
          borderRadius: 10,
          foregroundColor: colorScheme.iconDefault,
          hoverColor: colorScheme.surfaceContainerHighest,
          overlayColor: colorScheme.primary.withAlpha(32),
          delayTooltipThreeSeconds: false,
          onPressed: onRefresh,
        ),
        GhostButton.icon(
          icon: LucideIcons.wandSparkles,
          tooltip: '自动内容分级',
          semanticLabel: '自动内容分级',
          iconSize: 16,
          size: 24,
          borderRadius: 10,
          foregroundColor: colorScheme.iconDefault,
          hoverColor: colorScheme.surfaceContainerHighest,
          overlayColor: colorScheme.primary.withAlpha(32),
          delayTooltipThreeSeconds: false,
          onPressed: onAutoDetectContentRating,
        ),
        FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(LucideIcons.scanSearch, size: 18),
          label: const Text('扫描漫画库'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
