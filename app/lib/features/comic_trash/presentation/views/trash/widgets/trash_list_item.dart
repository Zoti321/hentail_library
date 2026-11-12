import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/features/comic_trash/presentation/views/trash/widgets/trash_list_sliver.dart';

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
      borderRadius: const BorderRadius.all(Radius.circular(kComicCardRadius)),
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
