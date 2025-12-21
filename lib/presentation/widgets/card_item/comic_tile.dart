import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/entities.dart';

class ComicTile extends StatefulWidget {
  final Comic comic;
  final VoidCallback onTap;
  final Function(TapDownDetails) onRightClick;

  const ComicTile({
    super.key,
    required this.comic,
    required this.onTap,
    required this.onRightClick,
  });

  @override
  State<ComicTile> createState() => _ComicTileState();
}

class _ComicTileState extends State<ComicTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),

      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: widget.onRightClick,

        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.surfaceContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              // 封面图片
              ClipRRect(
                borderRadius: .circular(6),
                child: Container(
                  width: 56,
                  height: 80,
                  color: Colors.grey[200],
                  child: ExtendedImage.file(
                    File(widget.comic.coverUrl!),
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // --- 文本信息 ---
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Text(
                      widget.comic.title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            '漫画',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.comic.totalPageCount}p',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(target: _isHovered ? 1 : 0),
      ),
    );
  }
}
