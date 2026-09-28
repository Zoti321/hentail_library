import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CatalogSelectableComicCard extends ConsumerWidget {
  const CatalogSelectableComicCard({
    super.key,
    required this.comic,
    required this.gridIndex,
    required this.onEditMetadata,
    required this.onOpenDetail,
  });

  final Comic comic;
  final int? gridIndex;
  final VoidCallback onEditMetadata;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    if (!selection.active) {
      return ComicCard(
        comic: comic,
        gridIndex: gridIndex,
        onEditMetadata: onEditMetadata,
        onTap: onOpenDetail,
      );
    }

    final bool selected = selection.selectedIds.contains(comic.comicId);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ComicCard(
          comic: comic,
          gridIndex: gridIndex,
          onEditMetadata: onEditMetadata,
          onTap: () =>
              ref.read(catalogSelectionProvider.notifier).toggle(comic.comicId),
          selectionMode: true,
        ),
        Positioned(
          top: tokens.spacing.xs,
          left: tokens.spacing.xs,
          child: Material(
            color: selected ? cs.primary : cs.surface.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius.xs),
              side: BorderSide(
                color: selected ? cs.primary : cs.hentai.borderSubtle,
              ),
            ),
            child: InkWell(
              onTap: () => ref
                  .read(catalogSelectionProvider.notifier)
                  .toggle(comic.comicId),
              child: SizedBox(
                width: 22,
                height: 22,
                child: selected
                    ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
