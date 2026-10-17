import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/confirm/clear_reading_history_confirm_dialog.dart';
import 'package:hentai_library/features/home/presentation/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/shared/ui/layout/page_header_layout.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HistoryPageHeaderSection extends ConsumerWidget {
  const HistoryPageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    this.onOpenNavigation,
  });

  final PageHeaderLayoutTier layoutTier;
  final double horizontalPadding;
  final double contentMaxWidth;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int totalCount = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> value) =>
            value.asData?.value.totalCount ?? 0,
      ),
    );

    return PageContentWidthAlign(
      horizontalPadding: horizontalPadding,
      maxWidth: contentMaxWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kPageHeaderVerticalPadding,
        ),
        child: HistoryPageHeaderToolbar(
          layoutTier: layoutTier,
          clearEnabled: totalCount > 0,
          onOpenNavigation: onOpenNavigation,
        ),
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

  final PageHeaderLayoutTier layoutTier;
  final bool clearEnabled;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final l10n = context.l10n;

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
                      semanticLabel: l10n.shellOpenNavMenu,
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
                    l10n.historyTitle,
                    style: pageHeaderTitleStyle(cs, layoutTier),
                  ),
                ],
              ),
            ),
          ),
          GhostButton.icon(
            icon: LucideIcons.trash2,
            tooltip: l10n.historyClearAction,
            semanticLabel: l10n.historyClearAction,
            onPressed: clearEnabled
                ? () => _clearAllHistory(context, ref)
                : null,
            iconSize: 16,
            size: 32,
            borderRadius: 8,
            foregroundColor: cs.hentai.error,
            hoverColor: cs.error.withAlpha(24),
            overlayColor: cs.error.withAlpha(20),
            delayTooltipThreeSeconds: true,
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
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
      await ref
          .read(historyPagedFeedControllerProvider.notifier)
          .clearAllHistory();
      if (context.mounted) {
        showSuccessToast(context, l10n.historyClearedToast);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, e);
      }
    }
  }
}
