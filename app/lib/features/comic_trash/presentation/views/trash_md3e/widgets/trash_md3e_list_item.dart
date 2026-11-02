import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const double _kCoverWidth = 48;
const double _kCoverHeight = 72;

/// 「已删除」列表行（MD3E）：选中指示、封面、标题、Local / Remote、所属 Library、删除时间。
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
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final String deletedAt = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(item.deletedAt.toLocal());
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Symbols.check_circle
                    : Symbols.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: _kCoverWidth,
                  height: _kCoverHeight,
                  child: ComicCoverContent(
                    comicId: item.comic.comicId,
                    priority: ThumbnailPriority.low,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: <Widget>[
                    Text(
                      item.comic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: <Widget>[
                        _Md3eTrashBadge(
                          text: item.isRemote
                              ? l10n.trashBadgeRemote
                              : l10n.trashBadgeLocal,
                        ),
                        Flexible(
                          child: Text(
                            item.libraryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.trashDeletedAt(deletedAt),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Md3eTrashBadge extends StatelessWidget {
  const _Md3eTrashBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
