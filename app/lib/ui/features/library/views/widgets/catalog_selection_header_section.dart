import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/features/library/views/widgets/catalog_selection_actions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 库页选择模式 pinned header：替换 [LibraryPageHeaderSection] 内容，复用相同 padding 与行高。
class CatalogSelectionHeaderSection extends ConsumerWidget {
  const CatalogSelectionHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    required this.pageComicIds,
    this.onOpenNavigation,
  });

  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;
  final List<String> pageComicIds;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kLibraryHeaderVerticalPadding,
        horizontalPadding,
        kLibraryHeaderVerticalPadding,
      ),
      child: CatalogSelectionHeaderToolbar(
        layoutTier: layoutTier,
        pageComicIds: pageComicIds,
        onOpenNavigation: onOpenNavigation,
      ),
    );
  }
}

class CatalogSelectionHeaderToolbar extends ConsumerWidget {
  const CatalogSelectionHeaderToolbar({
    super.key,
    required this.layoutTier,
    required this.pageComicIds,
    this.onOpenNavigation,
  });

  final LibraryLayoutTier layoutTier;
  final List<String> pageComicIds;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final bool showClear = selection.selectedIds.isNotEmpty;

    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          GhostButton.icon(
            icon: LucideIcons.x,
            tooltip: '',
            semanticLabel: l10n.catalogSelectionExit,
            iconSize: 16,
            size: 32,
            borderRadius: 8,
            foregroundColor: cs.hentai.iconDefault,
            hoverColor: theme.hoverColor,
            overlayColor: theme.hoverColor,
            onPressed: () => ref.read(catalogSelectionProvider.notifier).exit(),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: showClear
                ? () =>
                      ref.read(catalogSelectionProvider.notifier).clearSelection()
                : pageComicIds.isEmpty
                ? null
                : () => ref
                      .read(catalogSelectionProvider.notifier)
                      .selectPage(pageComicIds),
            child: Text(
              showClear
                  ? l10n.catalogSelectionClear
                  : l10n.catalogSelectionSelectPage,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: selection.count == 0
                ? null
                : () => openCatalogSelectionMetadataEditor(context, ref),
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: Text(l10n.catalogSelectionEditMetadata),
          ),
          const Spacer(),
          Text(
            l10n.catalogSelectionSelectedCount(selection.count),
            style: TextStyle(
              fontSize: tokens.text.bodyMd,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
