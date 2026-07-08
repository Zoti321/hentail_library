import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/clear_reading_history_confirm_dialog.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/history_layout_constants.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

TextStyle historyPageTitleStyle(
  ColorScheme colorScheme,
  HistoryLayoutTier layoutTier,
) {
  return TextStyle(
    color: colorScheme.hentai.textPrimary,
    fontSize: historyPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}

class HistoryPageHeaderSection extends ConsumerWidget {
  const HistoryPageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    this.onOpenNavigation,
  });

  final HistoryLayoutTier layoutTier;
  final double horizontalPadding;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int totalCount = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> value) =>
            value.asData?.value.totalCount ?? 0,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kHistoryHeaderVerticalPadding,
        horizontalPadding,
        kHistoryHeaderVerticalPadding,
      ),
      child: HistoryPageHeaderToolbar(
        layoutTier: layoutTier,
        clearEnabled: totalCount > 0,
        onOpenNavigation: onOpenNavigation,
      ),
    );
  }
}

class HistoryPageHeaderToolbar extends ConsumerWidget {
  const HistoryPageHeaderToolbar({
    super.key,
    required this.layoutTier,
    required this.clearEnabled,
    this.onOpenNavigation,
  });

  final HistoryLayoutTier layoutTier;
  final bool clearEnabled;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text('阅读历史', style: historyPageTitleStyle(cs, layoutTier)),
                ],
              ),
            ),
          ),
          GhostButton.icon(
            icon: LucideIcons.trash2,
            tooltip: '清空阅读历史',
            semanticLabel: '清空阅读历史',
            onPressed: clearEnabled
                ? () => _clearAllHistory(context, ref)
                : null,
            iconSize: 16,
            size: 32,
            borderRadius: 8,
            foregroundColor: cs.hentai.warning,
            hoverColor: cs.error.withAlpha(24),
            overlayColor: cs.error.withAlpha(20),
            delayTooltipThreeSeconds: true,
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory(BuildContext context, WidgetRef ref) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) =>
              const ClearReadingHistoryConfirmDialog(),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(readingHistoryRepoProvider).clearAllHistory();
      ref.read(historyPagedFeedControllerProvider.notifier).clearAllLocal();
      if (context.mounted) {
        showSuccessToast(context, '已清空阅读历史');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, e);
      }
    }
  }
}

class HistoryPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  HistoryPinnedHeaderDelegate({required this.extent, required this.child});

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
            height: kHistoryHeaderShadowGradientHeight,
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
  bool shouldRebuild(covariant HistoryPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
