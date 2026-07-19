import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/chrome/content_switcher_bottom_bar.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
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
    required this.contentMaxWidth,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onAdd,
    this.onOpenNavigation,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final double horizontalPadding;
  final double contentMaxWidth;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAdd;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    return PageContentWidthAlign(
      horizontalPadding: horizontalPadding,
      maxWidth: contentMaxWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kMetadataHeaderVerticalPadding,
        ),
        child: MetadataPageHeaderToolbar(
          layoutTier: layoutTier,
          selectedTabIndex: selectedTabIndex,
          onTabSelected: onTabSelected,
          onAdd: onAdd,
          onOpenNavigation: onOpenNavigation,
        ),
      ),
    );
  }
}

class MetadataPageHeaderToolbar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final String addTooltip = l10n.metadataAddEntityTooltip(selectedTabIndex);
    final bool showEntityTabs = metadataHeaderShowsEntityTabs(layoutTier);
    final bool showCountChip = metadataHeaderShowsCountChip(layoutTier);
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
                          semanticLabel: l10n.shellOpenNavMenu,
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
                        l10n.navMetadata,
                        style: metadataPageTitleStyle(cs, layoutTier),
                      ),
                      if (showCountChip) ...<Widget>[
                        const SizedBox(width: 12),
                        _MetadataActiveCountChip(
                          selectedTabIndex: selectedTabIndex,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              GhostButton.icon(
                icon: LucideIcons.plus,
                tooltip: addTooltip,
                semanticLabel: addTooltip,
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
          if (showEntityTabs)
            MetadataEntityTabs(
              selectedTabIndex: selectedTabIndex,
              onTabSelected: onTabSelected,
            ),
        ],
      ),
    );
  }
}

class _MetadataActiveCountChip extends ConsumerWidget {
  const _MetadataActiveCountChip({required this.selectedTabIndex});

  final int selectedTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final int count = selectedTabIndex == 0
        ? ref.watch(allAuthorsProvider).asData?.value.length ?? 0
        : ref.watch(allTagsProvider).asData?.value.length ?? 0;
    return CountDigitChip(
      count: count,
      semanticLabel: l10n.metadataTotalCount(count),
    );
  }
}

class MetadataEntityTabs extends StatelessWidget {
  const MetadataEntityTabs({
    required this.selectedTabIndex,
    required this.onTabSelected,
    super.key,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CapsuleTabBar(
      items: <CapsuleTabItem>[
        CapsuleTabItem(
          label: l10n.metadataTabAuthors,
          icon: LucideIcons.penLine,
        ),
        CapsuleTabItem(label: l10n.metadataTabTags, icon: LucideIcons.tags),
      ],
      selectedIndex: selectedTabIndex,
      onSelected: onTabSelected,
    );
  }
}

class MetadataEntityBottomBar extends StatelessWidget {
  const MetadataEntityBottomBar({
    required this.selectedTabIndex,
    required this.onTabSelected,
    super.key,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContentSwitcherBottomBar(
      items: <ContentSwitcherBottomBarItem>[
        (icon: LucideIcons.penLine, label: l10n.metadataTabAuthors),
        (icon: LucideIcons.tags, label: l10n.metadataTabTags),
      ],
      selectedIndex: selectedTabIndex,
      onSelected: onTabSelected,
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
