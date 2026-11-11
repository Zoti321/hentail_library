import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 列表项内复选框列宽（与 M3E 触控目标对齐）。
const double kTrashListCheckboxColumnWidth = 48;

/// 「已删除」列表行：catalog 卡片内左侧 [M3ECheckbox] 列 + 封面与文案。
class TrashListItem extends StatelessWidget {
  const TrashListItem({
    super.key,
    required this.item,
    required this.selected,
    required this.onToggleSelected,
  });

  final TrashedComic item;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final String deletedAt = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(item.deletedAt.toLocal());
    final String badge = item.isRemote
        ? l10n.trashBadgeRemote
        : l10n.trashBadgeLocal;
    final String? metaLine = ComicListItem.metaLine(
      author: badge,
      pageLabel: item.libraryName,
    );

    final Widget cover = ClipRRect(
      borderRadius: BorderRadius.circular(kComicCardRadius),
      child: SizedBox(
        width: kComicListItemCoverWidth,
        height: kComicListItemCoverHeight,
        child: ComicCoverContent(
          comicId: item.comic.comicId,
          priority: ThumbnailPriority.low,
        ),
      ),
    );

    final Widget infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          item.comic.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: comicCatalogTitleStyle(type, scheme),
        ),
        if (metaLine != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            metaLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: comicCatalogSubtitleStyle(type, scheme),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.trashDeletedAt(deletedAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: comicCatalogSubtitleStyle(type, scheme),
        ),
      ],
    );

    return ComicCatalogCardShell(
      height: kComicListItemMinHeight,
      width: double.infinity,
      enabled: true,
      trackHover: true,
      onPressed: onToggleSelected,
      selected: selected,
      semanticLabel: item.comic.title,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.sm,
          kComicListItemVerticalPadding,
          kComicCatalogContentHorizontalPadding,
          kComicListItemVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: kTrashListCheckboxColumnWidth,
              child: Center(
                child: M3ECheckbox(
                  value: selected,
                  onChanged: (_) => onToggleSelected(),
                ),
              ),
            ),
            SizedBox(width: spacing.sm),
            cover,
            SizedBox(width: spacing.md),
            Expanded(child: infoColumn),
          ],
        ),
      ),
    );
  }
}

/// 已删除列表 sliver：列数与库页列表视图一致（expanded 桌面端 3 列）。
class TrashListSliver extends StatelessWidget {
  const TrashListSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final int columns = comicListColumnCount(layout.sizeClass);
    final double gap = layout.listItemGap;

    if (itemCount <= 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (columns == 1) {
      return SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: itemBuilder(context, index),
          );
        },
      );
    }

    final int rowCount = (itemCount + columns - 1) ~/ columns;
    return SliverList.builder(
      itemCount: rowCount,
      itemBuilder: (BuildContext context, int rowIndex) {
        final int firstIndex = rowIndex * columns;
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int column = 0; column < columns; column++) ...<Widget>[
                if (column > 0) SizedBox(width: gap),
                Expanded(
                  child: firstIndex + column < itemCount
                      ? itemBuilder(context, firstIndex + column)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
