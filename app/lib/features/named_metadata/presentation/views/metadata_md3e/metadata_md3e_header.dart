import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_filled_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 元数据页粘滞头高度（与 Md3eLibraryPageHeaderMetrics 同款留白）。
const double kMetadataMd3eHeaderExtent =
    Md3eLibraryPageHeaderMetrics.verticalPadding +
    Md3eLibraryPageHeaderMetrics.toolbarHeight +
    Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding;

/// 粘滞头：普通模式为标题 + 数量 + 操作；合并模式为取消 + 「合并 N 个 tags」。
class MetadataMd3eHeader extends StatelessWidget {
  const MetadataMd3eHeader({
    required this.compact,
    required this.totalCount,
    required this.showDeleteAllTags,
    this.onOpenNavigation,
    this.onDeleteAllTags,
    this.mergeSelectionCount = 0,
    this.onExitMergeSelection,
    this.onMergeSelection,
    super.key,
  });

  final bool compact;
  final int totalCount;
  final bool showDeleteAllTags;
  final VoidCallback? onOpenNavigation;
  final VoidCallback? onDeleteAllTags;
  final int mergeSelectionCount;
  final VoidCallback? onExitMergeSelection;
  final VoidCallback? onMergeSelection;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    final Widget content;
    if (onExitMergeSelection != null) {
      content = Row(
        children: <Widget>[
          M3EIconButton(
            icon: const Icon(Symbols.close),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.sm,
            tooltip: l10n.commonCancel,
            semanticLabel: l10n.commonCancel,
            onPressed: onExitMergeSelection,
          ),
          const Spacer(),
          Md3eFilledButton(
            label: '${l10n.metadataMerge} $mergeSelectionCount tags',
            icon: Symbols.merge,
            onPressed: mergeSelectionCount > 1 ? onMergeSelection : null,
          ),
        ],
      );
    } else {
      content = Row(
        children: <Widget>[
          if (onOpenNavigation != null) ...<Widget>[
            M3EIconButton(
              icon: const Icon(Symbols.menu),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.shellOpenNavMenu,
              semanticLabel: l10n.shellOpenNavMenu,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              l10n.navMetadata,
              overflow: TextOverflow.ellipsis,
              style: type.headlineSmall.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (compact) ...<Widget>[
            const SizedBox(width: 12),
            Text(
              '$totalCount',
              style: type.labelLarge.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          if (showDeleteAllTags && onDeleteAllTags != null)
            M3EIconButton(
              icon: const Icon(Symbols.delete_sweep),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.commonDelete,
              semanticLabel: l10n.commonDelete,
              onPressed: onDeleteAllTags,
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: Md3eLibraryPageHeaderMetrics.verticalPadding,
        bottom: Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding,
      ),
      child: SizedBox(
        height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
        child: content,
      ),
    );
  }
}
