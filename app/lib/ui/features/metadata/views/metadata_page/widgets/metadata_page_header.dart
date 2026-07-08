import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

TextStyle metadataPageTitleStyle(
  ColorScheme colorScheme,
  MetadataLayoutTier layoutTier,
) {
  return TextStyle(
    fontSize: metadataPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    color: colorScheme.hentai.textPrimary,
    letterSpacing: -0.4,
  );
}

class MetadataPageHeaderSection extends StatelessWidget {
  const MetadataPageHeaderSection({
    required this.layoutTier,
    required this.horizontalPadding,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onAdd,
    this.onOpenNavigation,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final double horizontalPadding;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAdd;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kMetadataHeaderVerticalPadding,
        horizontalPadding,
        kMetadataHeaderVerticalPadding,
      ),
      child: MetadataPageHeaderToolbar(
        layoutTier: layoutTier,
        selectedTabIndex: selectedTabIndex,
        onTabSelected: onTabSelected,
        onAdd: onAdd,
        onOpenNavigation: onOpenNavigation,
      ),
    );
  }
}

class MetadataPageHeaderToolbar extends StatelessWidget {
  const MetadataPageHeaderToolbar({
    required this.layoutTier,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onAdd,
    this.onOpenNavigation,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAdd;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
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
                          hoverColor: Theme.of(context).hoverColor,
                          overlayColor: Theme.of(context).hoverColor,
                          onPressed: onOpenNavigation,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '管理',
                        style: metadataPageTitleStyle(cs, layoutTier),
                      ),
                    ],
                  ),
                ),
              ),
              GhostButton.icon(
                icon: LucideIcons.plus,
                tooltip: metadataAddEntityTooltip(selectedTabIndex),
                semanticLabel: metadataAddEntityTooltip(selectedTabIndex),
                iconSize: 16,
                size: 32,
                borderRadius: 8,
                foregroundColor: cs.hentai.iconDefault,
                hoverColor: Theme.of(context).hoverColor,
                overlayColor: Theme.of(context).hoverColor,
                delayTooltipThreeSeconds: true,
                onPressed: onAdd,
              ),
            ],
          ),
          MetadataEntityTabs(
            layoutTier: layoutTier,
            selectedTabIndex: selectedTabIndex,
            onTabSelected: onTabSelected,
          ),
        ],
      ),
    );
  }
}

class MetadataEntityTabs extends StatelessWidget {
  const MetadataEntityTabs({
    required this.layoutTier,
    required this.selectedTabIndex,
    required this.onTabSelected,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  static const List<CapsuleTabItem> _capsuleItems = <CapsuleTabItem>[
    CapsuleTabItem(label: '作者', icon: LucideIcons.penLine),
    CapsuleTabItem(label: '标签', icon: LucideIcons.tags),
  ];

  @override
  Widget build(BuildContext context) {
    if (layoutTier == MetadataLayoutTier.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _MetadataUnderlineTab(
            label: '作者',
            isSelected: selectedTabIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          const SizedBox(width: 16),
          _MetadataUnderlineTab(
            label: '标签',
            isSelected: selectedTabIndex == 1,
            onTap: () => onTabSelected(1),
          ),
        ],
      );
    }

    return CapsuleTabBar(
      items: _capsuleItems,
      selectedIndex: selectedTabIndex,
      onSelected: onTabSelected,
    );
  }
}

class _MetadataUnderlineTab extends StatelessWidget {
  const _MetadataUnderlineTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.hentai.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: label.length * 14.0,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const double kMetadataHeaderShadowGradientHeight = 6;

class MetadataPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  MetadataPinnedHeaderDelegate({required this.extent, required this.child});

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
            height: kMetadataHeaderShadowGradientHeight,
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
  bool shouldRebuild(covariant MetadataPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
