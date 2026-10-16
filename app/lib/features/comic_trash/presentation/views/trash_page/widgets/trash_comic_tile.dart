import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kTrashCoverWidth = 48;
const double _kTrashCoverHeight = 72;

/// 「已删除」列表项：缩略图、标题、所属 Library、删除时间、Local / Remote 标识。
class TrashComicTile extends StatelessWidget {
  const TrashComicTile({
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final String deletedAt = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(item.deletedAt.toLocal());
    return Material(
      color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radius.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radius.xs),
        onTap: onToggleSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: _kTrashCoverWidth,
                      height: _kTrashCoverHeight,
                      child: ComicCoverContent(
                        comicId: item.comic.comicId,
                        priority: ThumbnailPriority.low,
                      ),
                    ),
                  ),
                  Positioned(
                    top: tokens.spacing.xs,
                    left: tokens.spacing.xs,
                    child: Material(
                      color: selected
                          ? cs.primary
                          : cs.surface.withValues(alpha: 0.92),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radius.xs),
                        side: BorderSide(
                          color: selected ? cs.primary : cs.hentai.borderSubtle,
                        ),
                      ),
                      child: InkWell(
                        onTap: onToggleSelected,
                        borderRadius: BorderRadius.circular(tokens.radius.xs),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: selected
                              ? Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: cs.onPrimary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: <Widget>[
                        OutlinedMetaChip(
                          compact: true,
                          text: item.isRemote
                              ? l10n.trashBadgeRemote
                              : l10n.trashBadgeLocal,
                        ),
                        Flexible(
                          child: Text(
                            item.libraryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.hentai.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.trashDeletedAt(deletedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.hentai.textTertiary,
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
