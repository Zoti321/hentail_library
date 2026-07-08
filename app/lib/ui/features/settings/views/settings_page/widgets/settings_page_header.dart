import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 粘连 header：左汉堡(仅 compact)+标题；右侧留空。通栏背景由 [SettingsPinnedHeaderDelegate] 提供。
class SettingsPageHeaderSection extends StatelessWidget {
  const SettingsPageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    this.onOpenNavigation,
  });

  final SettingsLayoutTier layoutTier;
  final double horizontalPadding;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kSettingsHeaderVerticalPadding,
        horizontalPadding,
        kSettingsHeaderVerticalPadding,
      ),
      child: SettingsPageHeaderToolbar(
        layoutTier: layoutTier,
        onOpenNavigation: onOpenNavigation,
      ),
    );
  }
}

class SettingsPageHeaderToolbar extends StatelessWidget {
  const SettingsPageHeaderToolbar({
    super.key,
    required this.layoutTier,
    this.onOpenNavigation,
  });

  final SettingsLayoutTier layoutTier;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

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
                      foregroundColor: cs.hentai.iconDefault,
                      hoverColor: theme.hoverColor,
                      overlayColor: theme.hoverColor,
                      onPressed: onOpenNavigation,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '设置',
                    style: buildSettingsPageTitleStyle(cs, layoutTier),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  SettingsPinnedHeaderDelegate({required this.extent, required this.child});

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
            height: kSettingsHeaderShadowGradientHeight,
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
  bool shouldRebuild(covariant SettingsPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
