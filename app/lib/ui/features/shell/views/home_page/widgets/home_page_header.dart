import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kHomeHeaderVerticalPadding = 6;
const double kHomeHeaderShadowGradientHeight = 6;

TextStyle homePageTitleStyle(
  ColorScheme colorScheme,
  HomePageLayoutTier layoutTier,
) {
  return TextStyle(
    color: colorScheme.hentai.textPrimary,
    fontSize: homePageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}

TextStyle homePageSubtitleStyle(ColorScheme colorScheme) {
  return TextStyle(color: colorScheme.hentai.textTertiary, fontSize: 13);
}

/// 粘连 header：左汉堡(仅 compact)+标题，右扫描按钮；通栏背景由 [HomePinnedHeaderDelegate] 提供。
class HomePageHeaderSection extends StatelessWidget {
  const HomePageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    required this.onScan,
    this.onOpenNavigation,
  });

  final HomePageLayoutTier layoutTier;
  final double horizontalPadding;
  final VoidCallback onScan;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kHomeHeaderVerticalPadding,
        horizontalPadding,
        kHomeHeaderVerticalPadding,
      ),
      child: HomePageHeaderToolbar(
        layoutTier: layoutTier,
        onScan: onScan,
        onOpenNavigation: onOpenNavigation,
      ),
    );
  }
}

class HomePageHeaderToolbar extends StatelessWidget {
  const HomePageHeaderToolbar({
    super.key,
    required this.layoutTier,
    required this.onScan,
    this.onOpenNavigation,
  });

  final HomePageLayoutTier layoutTier;
  final VoidCallback onScan;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '首页',
                    style: homePageTitleStyle(colorScheme, layoutTier),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}

class HomePinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  HomePinnedHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(alignment: Alignment.topCenter, child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: kHomeHeaderShadowGradientHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      cs.hentai.cardShadow.withValues(alpha: 0),
                      cs.hentai.cardShadow.withValues(alpha: 0.025),
                      cs.hentai.cardShadow.withValues(alpha: 0.05),
                    ],
                    stops: const <double>[0, 0.75, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomePinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
