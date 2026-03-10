import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/reading_history.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 阅读历史卡片：展示单条 [ReadingHistory]，风格与 [ComicTile] 一致，横向封面 + 标题 + 阅读时间/进度。
class ReadingHistoryCard extends StatefulWidget {
  final ReadingHistory history;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ReadingHistoryCard({
    super.key,
    required this.history,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<ReadingHistoryCard> createState() => _ReadingHistoryCardState();
}

class _ReadingHistoryCardState extends State<ReadingHistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final h = widget.history;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
          decoration: BoxDecoration(
            color: _isHovered ? cs.surfaceContainer : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              _buildCover(cs, h.coverUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      h.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: cs.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatLastRead(h.lastReadTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.textTertiary,
                          ),
                        ),
                        if (h.pageIndex != null && h.pageIndex! > 0) ...[
                          const SizedBox(width: 12),
                          Text(
                            '第 ${h.pageIndex} 页',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: cs.textTertiary,
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: '删除记录',
                  child: IconButton(
                    onPressed: widget.onDelete,
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: cs.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
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
        child: coverUrl != null &&
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
}
