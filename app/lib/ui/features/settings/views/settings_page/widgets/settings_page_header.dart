import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sticky header: back + title; full-bleed background from [SettingsPinnedHeaderDelegate].
///
/// [title] defaults to 「设置」; on narrow detail pass the selected category label.
class SettingsPageHeaderSection extends StatelessWidget {
  const SettingsPageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    required this.onBack,
    this.title,
  });

  final SettingsLayoutTier layoutTier;
  final double horizontalPadding;
  final double contentMaxWidth;
  final VoidCallback onBack;

  /// When null, uses [AppLocalizations.navSettings].
  final String? title;

  @override
  Widget build(BuildContext context) {
    return PageContentWidthAlign(
      horizontalPadding: horizontalPadding,
      maxWidth: contentMaxWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kSettingsHeaderVerticalPadding,
        ),
        child: SettingsPageHeaderToolbar(
          layoutTier: layoutTier,
          onBack: onBack,
          title: title,
        ),
      ),
    );
  }
}

class SettingsPageHeaderToolbar extends StatelessWidget {
  const SettingsPageHeaderToolbar({
    super.key,
    required this.layoutTier,
    required this.onBack,
    this.title,
  });

  final SettingsLayoutTier layoutTier;
  final VoidCallback onBack;

  /// When null, uses [AppLocalizations.navSettings].
  final String? title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final l10n = context.l10n;
    final String resolvedTitle = title ?? l10n.navSettings;

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
                  GhostButton.icon(
                    icon: LucideIcons.arrowLeft,
                    semanticLabel: l10n.shellBack,
                    tooltip: l10n.shellBack,
                    iconSize: 16,
                    size: 32,
                    borderRadius: 8,
                    foregroundColor: cs.hentai.iconDefault,
                    hoverColor: theme.hoverColor,
                    overlayColor: theme.hoverColor,
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: kSettingsNarrowPaneTransitionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Text(
                      resolvedTitle,
                      key: ValueKey<String>(resolvedTitle),
                      style: buildSettingsPageTitleStyle(cs, layoutTier),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Leave settings: pop when possible, otherwise go home.
  static void popOrGoHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
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
