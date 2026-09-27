import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/ui/features/library/views/widgets/catalog_selection_actions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CatalogSelectionToolbar extends ConsumerWidget {
  const CatalogSelectionToolbar({
    super.key,
    required this.pageComicIds,
  });

  final List<String> pageComicIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    if (!selection.active) {
      return const SizedBox.shrink();
    }
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Material(
      color: cs.primary.withValues(alpha: 0.06),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.hentai.borderSubtle)),
        ),
        child: Row(
          children: <Widget>[
            Text(
              l10n.catalogSelectionSelectedCount(selection.count),
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                fontWeight: FontWeight.w600,
                color: cs.hentai.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: pageComicIds.isEmpty
                  ? null
                  : () => ref
                        .read(catalogSelectionProvider.notifier)
                        .selectPage(pageComicIds),
              child: Text(l10n.catalogSelectionSelectPage),
            ),
            TextButton(
              onPressed: selection.count == 0
                  ? null
                  : () =>
                        ref.read(catalogSelectionProvider.notifier).clearSelection(),
              child: Text(l10n.catalogSelectionClear),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: selection.count == 0
                  ? null
                  : () => openCatalogSelectionMetadataEditor(context, ref),
              icon: const Icon(LucideIcons.pencil, size: 16),
              label: Text(l10n.catalogSelectionEditMetadata),
            ),
            const SizedBox(width: 8),
            GhostButton.text(
              text: l10n.catalogSelectionExit,
              onPressed: () =>
                  ref.read(catalogSelectionProvider.notifier).exit(),
            ),
          ],
        ),
      ),
    );
  }
}
