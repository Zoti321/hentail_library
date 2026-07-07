import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReadingHistoryCard extends ConsumerStatefulWidget {
  const ReadingHistoryCard({
    super.key,
    required this.comicId,
    required this.title,
    required this.lastReadTime,
    required this.pageIndex,
    required this.onTap,
    this.onDelete,
  });

  final String comicId;
  final String title;
  final DateTime lastReadTime;
  final int? pageIndex;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  ConsumerState<ReadingHistoryCard> createState() => _ReadingHistoryCardState();
}

class _ReadingHistoryCardState extends ConsumerState<ReadingHistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ComicCoverState coverState = ref.watch(
      comicCoverProvider(widget.comicId),
    );
    final coverDisplay = comicCoverImageOrPrevious(coverState);

    final Color cardBackground = _isHovered ? cs.surfaceContainer : cs.surface;
    final Color cardBorderColor = _isHovered
        ? cs.hentai.borderStrong
        : cs.hentai.borderSubtle;
    final List<BoxShadow> cardShadows = _isHovered
        ? <BoxShadow>[
            BoxShadow(
              color: cs.shadow.withAlpha(28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: cardShadows,
          ),
          child: Row(
            children: [
              _buildCover(cs, coverState, coverDisplay),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: cs.hentai.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatLastRead(widget.lastReadTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.hentai.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (_buildProgressLabel().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _buildProgressLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.hentai.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(width: 6),
                GhostButton.icon(
                  icon: LucideIcons.trash2,
                  tooltip: '删除记录',
                  semanticLabel: '删除记录',
                  onPressed: widget.onDelete,
                  iconSize: 18,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.textTertiary,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor.withAlpha(110),
                  delayTooltipThreeSeconds: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(
    ColorScheme cs,
    ComicCoverState coverState,
    ComicCoverImage? coverDisplay,
  ) {
    const double coverWidth = 74;
    const double coverHeight = 102;
    const double coverOuterInset = 3;

    final Widget historyPlaceholder = Center(
      child: Icon(
        LucideIcons.bookOpen,
        size: 28,
        color: cs.hentai.textTertiary,
      ),
    );

    final Widget placeholder = switch (coverState) {
      ComicCoverError() => historyPlaceholder,
      ComicCoverNoCover() => historyPlaceholder,
      _ => ColoredBox(color: cs.surfaceContainerHighest),
    };

    final Widget image = coverDisplay == null
        ? placeholder
        : AppComicImage(
            filePath: coverDisplay.filePath,
            memoryBytes: coverDisplay.memoryBytes,
            fit: BoxFit.cover,
            placeholder: placeholder,
            errorPlaceholder: historyPlaceholder,
          );

    return Padding(
      padding: const EdgeInsets.all(coverOuterInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: coverWidth,
          height: coverHeight,
          color: cs.surfaceContainerHighest,
          child: image,
        ),
      ),
    );
  }

  String _formatLastRead(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${time.month}/${time.day}';
  }

  String _buildProgressLabel() {
    final int? pageIndex = widget.pageIndex;
    if (pageIndex == null || pageIndex <= 0) {
      return '';
    }
    return '第 $pageIndex 页';
  }
}
