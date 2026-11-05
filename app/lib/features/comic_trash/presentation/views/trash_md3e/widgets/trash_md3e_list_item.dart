import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 列表项内复选框列宽（与 M3E 触控目标对齐）。
const double kTrashMd3eListCheckboxColumnWidth = 48;

/// 「已删除」列表行：catalog 卡片内左侧 [M3ECheckbox] 列 + 封面与文案。
class TrashMd3eListItem extends StatelessWidget {
  const TrashMd3eListItem({
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
    final String? metaLine = Md3eComicListItem.metaLine(
      author: badge,
      pageLabel: item.libraryName,
    );

    final Widget cover = ClipRRect(
      borderRadius: BorderRadius.circular(kMd3eComicCardRadius),
      child: SizedBox(
        width: kMd3eComicListItemCoverWidth,
        height: kMd3eComicListItemCoverHeight,
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
          style: md3eComicCatalogTitleStyle(type, scheme),
        ),
        if (metaLine != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            metaLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: md3eComicCatalogSubtitleStyle(type, scheme),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.trashDeletedAt(deletedAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: md3eComicCatalogSubtitleStyle(type, scheme),
        ),
      ],
    );

    return Md3eComicCatalogCardShell(
      height: kMd3eComicListItemMinHeight,
      width: double.infinity,
      enabled: true,
      trackHover: true,
      onPressed: onToggleSelected,
      selected: selected,
      semanticLabel: item.comic.title,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.sm,
          kMd3eComicListItemVerticalPadding,
          kMd3eComicCatalogContentHorizontalPadding,
          kMd3eComicListItemVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: kTrashMd3eListCheckboxColumnWidth,
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
class TrashMd3eListSliver extends StatelessWidget {
  const TrashMd3eListSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final int columns = md3eComicListColumnCount(layout.sizeClass);
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
