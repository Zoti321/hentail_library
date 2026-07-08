import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/selected_paths_layout_constants.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/widgets/add_path_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sticky header: back + title on the left, add-path on the right.
/// Full-bleed background comes from [SelectedPathsPinnedHeaderDelegate].
class SelectedPathsPageHeaderSection extends StatelessWidget {
  const SelectedPathsPageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
  });

  final SelectedPathsLayoutTier layoutTier;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kSelectedPathsHeaderVerticalPadding,
        horizontalPadding,
        kSelectedPathsHeaderVerticalPadding,
      ),
      child: SelectedPathsPageHeaderToolbar(layoutTier: layoutTier),
    );
  }
}

class SelectedPathsPageHeaderToolbar extends StatelessWidget {
  const SelectedPathsPageHeaderToolbar({
    super.key,
    required this.layoutTier,
  });

  final SelectedPathsLayoutTier layoutTier;

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
                children: <Widget>[
                  GhostButton.icon(
                    icon: LucideIcons.arrowLeft,
                    tooltip: '返回',
                    semanticLabel: '返回设置',
                    iconSize: 16,
                    size: 32,
                    borderRadius: 8,
                    foregroundColor: cs.hentai.iconDefault,
                    hoverColor: theme.hoverColor,
                    overlayColor: theme.hoverColor,
                    onPressed: () => popOrGoSettings(context),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '选中路径',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: buildSelectedPathsPageTitleStyle(cs, layoutTier),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const AddPathButton(),
        ],
      ),
    );
  }

  static void popOrGoSettings(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/settings');
  }
}

class SelectedPathsPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  SelectedPathsPinnedHeaderDelegate({
    required this.extent,
    required this.child,
  });

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
            height: kSelectedPathsHeaderShadowGradientHeight,
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
  bool shouldRebuild(covariant SelectedPathsPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

TextStyle buildSelectedPathsPageTitleStyle(
  ColorScheme colorScheme,
  SelectedPathsLayoutTier layoutTier,
) {
  return TextStyle(
    fontSize: selectedPathsPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: colorScheme.hentai.textPrimary,
  );
}
