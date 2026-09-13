import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_controller.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Series reorder mode 的成员区（#121）：关闭分页、加载全部成员、整卡拖拽重排。
class SeriesReorderBody extends ConsumerWidget {
  const SeriesReorderBody({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<SeriesComicPageItem>> membersAsync = ref.watch(
      seriesReorderControllerProvider(seriesId),
    );

    return membersAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(
        child: Text(
          l10n.seriesDetailComicsLoadFailed,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      ),
      data: (List<SeriesComicPageItem> items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              l10n.seriesDetailNoComics,
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textTertiary,
              ),
            ),
          );
        }
        return _SeriesReorderGrid(seriesId: seriesId, items: items);
      },
    );
  }
}

class _SeriesReorderGrid extends HookConsumerWidget {
  const _SeriesReorderGrid({required this.seriesId, required this.items});

  final String seriesId;
  final List<SeriesComicPageItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScrollController scrollController = useScrollController();
    // flutter_reorderable_grid_view casts the builder child's key to GlobalKey
    // for drag-while-scroll; ValueKey/Key here throws at build time.
    final GlobalKey gridViewKey = useMemoized(GlobalKey.new);
    final AppThemeTokens tokens = context.tokens;
    final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final SliverGridDelegate gridDelegate = libraryGridDelegateForTokens(
      tokens,
      layoutTier,
    );
    final double horizontalPadding = libraryContentHorizontalPadding(
      layoutTier,
    );

    final List<Widget> children = <Widget>[
      for (final SeriesComicPageItem item in items)
        _SeriesReorderCard(
          key: ValueKey<String>(item.comic.comicId),
          item: item,
        ),
    ];

    return ReorderableBuilder<SeriesComicPageItem>(
      scrollController: scrollController,
      longPressDelay: const Duration(milliseconds: 120),
      onReorder: (ReorderedListFunction<SeriesComicPageItem> reorderFunction) {
        final List<SeriesComicPageItem> updated = reorderFunction(items);
        _persist(context, ref, updated);
      },
      children: children,
      builder: (List<Widget> reorderedChildren) {
        return GridView(
          key: gridViewKey,
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            tokens.spacing.lg,
            horizontalPadding,
            tokens.spacing.xl + 8,
          ),
          gridDelegate: gridDelegate,
          children: reorderedChildren,
        );
      },
    );
  }

  void _persist(
    BuildContext context,
    WidgetRef ref,
    List<SeriesComicPageItem> updated,
  ) {
    ref
        .read(seriesReorderControllerProvider(seriesId).notifier)
        .reorder(updated)
        .catchError((Object error) {
          if (context.mounted) {
            showErrorToast(context, error);
          }
        });
  }
}

class _SeriesReorderCard extends StatelessWidget {
  const _SeriesReorderCard({super.key, required this.item});

  final SeriesComicPageItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: CatalogCoverCardShell(
        cover: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ComicCoverContent(comicId: item.comic.comicId),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.xs),
                child: _ReorderBadge(
                  semanticLabel: l10n.seriesDetailReorderBadgeSemantic,
                ),
              ),
            ),
          ],
        ),
        info: (bool isHover) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: <Widget>[
            Text(
              item.comic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                fontWeight: FontWeight.w600,
                fontFamily: 'MI_Sans_Regular',
                height: 1.25,
                color: cs.hentai.textPrimary,
              ),
            ),
            Text(
              l10n.comicDetailPageCount(item.comic.pageCount),
              style: TextStyle(
                fontSize: tokens.text.labelXs - 1,
                color: cs.hentai.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左上角拖拽模式角标：primaryContainer 背景 + gripVertical（#121）。
class _ReorderBadge extends StatelessWidget {
  const _ReorderBadge({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: EdgeInsets.all(tokens.spacing.xs),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(tokens.radius.sm),
        ),
        child: Icon(
          LucideIcons.gripVertical,
          size: 14,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
