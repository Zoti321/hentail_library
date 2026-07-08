import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

TextStyle _buildDesktopPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    color: colorScheme.hentai.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({
    super.key,
    required this.layoutTier,
    required this.title,
    required this.greetingText,
    required this.onScan,
    this.onOpenNavigation,
  });

  final HomePageLayoutTier layoutTier;
  final String title;
  final String greetingText;
  final VoidCallback onScan;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final _HomeHeaderTextBlock textBlock = _HomeHeaderTextBlock(
      title: title,
      greetingText: greetingText,
      colorScheme: colorScheme,
      tokens: tokens,
    );
    final _HomeHeaderActionBlock actionBlock = _HomeHeaderActionBlock(
      colorScheme: colorScheme,
      onScan: onScan,
    );
    if (layoutTier == HomePageLayoutTier.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (onOpenNavigation != null) ...<Widget>[
            GhostButton.icon(
              icon: LucideIcons.menu,
              semanticLabel: '打开导航菜单',
              tooltip: '',
              iconSize: 16,
              size: 32,
              borderRadius: 8,
              foregroundColor: colorScheme.hentai.iconDefault,
              hoverColor: theme.hoverColor,
              overlayColor: theme.hoverColor,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(height: 8),
          ],
          textBlock,
          SizedBox(height: tokens.spacing.md),
          actionBlock,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[textBlock, actionBlock],
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
          style: TextStyle(
            color: colorScheme.hentai.textTertiary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _HomeHeaderActionBlock extends StatelessWidget {
  const _HomeHeaderActionBlock({
    required this.colorScheme,
    required this.onScan,
  });

  final ColorScheme colorScheme;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
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
    );
  }
}
