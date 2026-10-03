import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
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
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelected,
    required this.onRestore,
    required this.onPurge,
  });

  final TrashedComic item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

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
        onTap: selectionMode ? onToggleSelected : null,
        onLongPress: selectionMode ? null : onToggleSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: <Widget>[
              if (selectionMode)
                Checkbox(value: selected, onChanged: (_) => onToggleSelected()),
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
              if (!selectionMode) ...<Widget>[
                GhostButton.iconText(
                  icon: LucideIcons.undo2,
                  text: l10n.trashRestore,
                  onPressed: onRestore,
                ),
                GhostButton.icon(
                  icon: LucideIcons.trash2,
                  tooltip: l10n.trashPurge,
                  semanticLabel: l10n.trashPurge,
                  foregroundColor: cs.hentai.contextMenuDanger,
                  hoverColor: cs.hentai.contextMenuDanger.withAlpha(24),
                  overlayColor: cs.hentai.contextMenuDanger.withAlpha(20),
                  onPressed: onPurge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
