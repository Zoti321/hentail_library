import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_title.dart';
import 'package:hentai_library/shared/ui/widgets/actions/filled_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 粘滞头：普通模式为标题 + 操作；合并模式为取消 + 「合并 N 个 tags」。
///
/// 上下留白与水平留白由外层 [PageHeaderDelegate] 提供，本组件只负责工具行。
class MetadataHeader extends StatelessWidget {
  const MetadataHeader({
    this.onOpenNavigation,
    this.mergeSelectionCount = 0,
    this.onExitMergeSelection,
    this.onMergeSelection,
    super.key,
  });

  final VoidCallback? onOpenNavigation;
  final int mergeSelectionCount;
  final VoidCallback? onExitMergeSelection;
  final VoidCallback? onMergeSelection;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

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
          ExpressiveFilledButton(
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
          Flexible(child: PageTitle(l10n.navMetadata)),
          const Spacer(),
        ],
      );
    }

    return SizedBox(
      height: PageLayoutSpec.toolbarRowHeight,
      child: content,
    );
  }
}
