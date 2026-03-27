import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/v2/library_comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicTile extends HookConsumerWidget {
  final LibraryComic comic;
  final VoidCallback onTap;
  final Function(TapDownDetails) onRightClick;

  const ComicTile({
    super.key,
    required this.comic,
    required this.onTap,
    required this.onRightClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isHovered = useState(false);
    final coverPath = ref
        .watch(comicCoverPathProvider(comicId: comic.comicId))
        .maybeWhen(data: (v) => v, orElse: () => null);
    final pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(data: (files) => files.length, orElse: () => 0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,

      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapDown: onRightClick,

        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          decoration: BoxDecoration(
            color: isHovered.value
                ? theme.colorScheme.surfaceContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              // 封面图片
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 56,
                  height: 80,
                  color: Colors.grey[200],
                  child: coverPath != null
                      ? ExtendedImage.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        )
                      : Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 16),

              // --- 文本信息 ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Text(
                      comic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            comic.resourceType.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${pageCount}p',
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
        ).animate(target: isHovered.value ? 1 : 0),
      ),
    );
  }
}
