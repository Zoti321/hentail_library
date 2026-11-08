import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/metadata_backup/public.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_actions.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/motion/mode_chrome_transition.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header_back_button.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_title.dart';
import 'package:hentai_library/shared/ui/theme/lab_text.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 粘滞头：普通模式为返回 + 标题 + 右侧更多；合并模式为取消 + 右侧 M3E filled 合并。
///
/// 上下留白与水平留白由外层 [PageHeaderDelegate] 提供，本组件只负责工具行。
class MetadataHeader extends ConsumerWidget {
  const MetadataHeader({
    this.onOpenNavigation,
    this.onBack,
    this.mergeSelectionCount = 0,
    this.onExitMergeSelection,
    this.onMergeSelection,
    super.key,
  });

  final VoidCallback? onOpenNavigation;
  final VoidCallback? onBack;
  final int mergeSelectionCount;
  final VoidCallback? onExitMergeSelection;
  final VoidCallback? onMergeSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool mergeMode = onExitMergeSelection != null;
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle mergeLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );

    final Widget content;
    if (mergeMode) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          M3EButton(
            onPressed: mergeSelectionCount > 1 ? onMergeSelection : null,
            style: M3EButtonStyle.filled,
            decoration: M3EButtonDecoration(textStyle: mergeLabelStyle),
            icon: const Icon(Symbols.merge),
            label: Text(l10n.metadataMergeSelectionLabel(mergeSelectionCount)),
          ),
        ],
      );
    } else {
      final bool showMenu =
          PageLayoutSpec.of(context).sizeClass.isCompact &&
          onOpenNavigation != null;
      final M3EColorScheme scheme = theme.colorScheme;
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            PageHeaderBackButton(onPressed: onBack!),
            const SizedBox(width: 4),
          ],
          if (showMenu) ...<Widget>[
            M3EIconButton(
              icon: Icon(
                Symbols.menu,
                size: LibraryPageHeaderMetrics.actionIconSize,
                color: scheme.onSurfaceVariant,
              ),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.shellOpenNavMenu,
              semanticLabel: l10n.shellOpenNavMenu,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PageTitle(l10n.navMetadata),
            ),
          ),
          AnchoredMenu(
            position: M3EMenuAnchorPosition.bottomEnd,
            children: <M3EMenuNode>[
              M3EMenuEntry(
                label: l10n.settingsMetadataBackupExportLabel,
                leading: const Icon(Icons.download_outlined),
                onPressed: () => runMetadataExportFlow(
                  context,
                  initialOptions: const MetadataExportOptions(),
                ),
              ),
              M3EMenuEntry(
                label: l10n.metadataImportTagDictionaryMenuLabel,
                leading: const Icon(Icons.upload_file_outlined),
                onPressed: () => unawaited(
                  importTagDictionaryFromFile(context, ref),
                ),
              ),
            ],
            anchorBuilder: (BuildContext context, VoidCallback open) {
              return M3EIconButton(
                icon: const Icon(Symbols.more_vert),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: l10n.metadataMoreActions,
                semanticLabel: l10n.metadataMoreActions,
                onPressed: open,
              );
            },
          ),
        ],
      );
    }

    return SizedBox(
      height: PageLayoutSpec.toolbarRowHeight,
      width: double.infinity,
      child: ModeChromeTransition(
        switchKey: mergeMode,
        reverse: !mergeMode,
        child: content,
      ),
    );
  }
}
