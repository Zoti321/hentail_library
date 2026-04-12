import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_page_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReadingHistoryCard extends ConsumerStatefulWidget {
  const ReadingHistoryCard.comic({
    super.key,
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int? pageIndex,
    required this.onTap,
    this.onDelete,
  }) : _kind = _ReadingHistoryCardKind.comic,
       _comicId = comicId,
       _lastReadComicId = null,
       _lastReadComicOrder = null,
       _title = title,
       _lastReadTime = lastReadTime,
       _pageIndex = pageIndex;

  const ReadingHistoryCard.series({
    super.key,
    required String seriesName,
    required String lastReadComicId,
    required DateTime lastReadTime,
    required int? pageIndex,
    required int? lastReadComicOrder,
    required this.onTap,
    this.onDelete,
  }) : _kind = _ReadingHistoryCardKind.series,
       _comicId = null,
       _lastReadComicId = lastReadComicId,
       _lastReadComicOrder = lastReadComicOrder,
       _title = seriesName,
       _lastReadTime = lastReadTime,
       _pageIndex = pageIndex;

  final _ReadingHistoryCardKind _kind;
  final String? _comicId;
  final String? _lastReadComicId;
  final int? _lastReadComicOrder;
  final String _title;
  final DateTime _lastReadTime;
  final int? _pageIndex;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  ConsumerState<ReadingHistoryCard> createState() => _ReadingHistoryCardState();
}

enum _ReadingHistoryCardKind { comic, series }

class _ReadingHistoryCardState extends ConsumerState<ReadingHistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isSeries = widget._kind == _ReadingHistoryCardKind.series;
    final Color tintedBackground = isSeries
        ? cs.primary.withAlpha(_isHovered ? 24 : 12)
        : cs.surface;
    final Color kindColor = isSeries ? cs.primary : cs.secondary;
    final String kindLabel = isSeries ? '系列' : '漫画';
    final String coverComicId = widget._kind == _ReadingHistoryCardKind.comic
        ? widget._comicId!
        : widget._lastReadComicId!;

    final coverUrl = ref
        .watch(comicCoverPathProvider(comicId: coverComicId))
        .maybeWhen(data: (v) => v, orElse: () => null);

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
            color: isSeries
                ? tintedBackground
                : (_isHovered ? cs.surfaceContainer : cs.surface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? (isSeries ? cs.primary.withAlpha(140) : cs.borderStrong)
                  : (isSeries ? cs.primary.withAlpha(80) : cs.borderSubtle),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: cs.shadow.withAlpha(28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            children: [
              _buildCover(cs, coverUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _buildKindChip(
                          cs: cs,
                          label: kindLabel,
                          color: kindColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget._title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: cs.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatLastRead(widget._lastReadTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (_buildProgressLabel().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildProgressChip(cs),
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
                  foregroundColor: cs.textTertiary,
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

  Widget _buildKindChip({
    required ColorScheme cs,
    required String label,
    required Color color,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChip(ColorScheme cs) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          _buildProgressLabel(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme cs, String? coverUrl) {
    const width = 56.0;
    const height = 80.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        child:
            coverUrl != null &&
                coverUrl.isNotEmpty &&
                File(coverUrl).existsSync()
            ? ExtendedImage.file(
                File(coverUrl),
                fit: BoxFit.cover,
                cacheWidth: 168,
              )
            : Center(
                child: Icon(
                  LucideIcons.bookOpen,
                  size: 24,
                  color: cs.textTertiary,
                ),
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
    if (widget._kind == _ReadingHistoryCardKind.comic) {
      final int? pageIndex = widget._pageIndex;
      if (pageIndex == null || pageIndex <= 0) {
        return '';
      }
      return '第 $pageIndex 页';
    }
    final int? order = widget._lastReadComicOrder;
    final int? pageIndex = widget._pageIndex;
    if (order != null && order >= 0) {
      final int displayOrder = order + 1;
      if (pageIndex == null || pageIndex <= 0) {
        return '第 $displayOrder 话';
      }
      return '第 $displayOrder 话 · 第 $pageIndex 页';
    }
    if (pageIndex == null || pageIndex <= 0) {
      return '';
    }
    return '第 $pageIndex 页';
  }
}
