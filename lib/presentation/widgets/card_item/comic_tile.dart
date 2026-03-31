import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicTile extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
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
          margin: EdgeInsets.only(bottom: tokens.spacing.md),
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.sm,
            tokens.spacing.sm,
            tokens.spacing.lg,
            tokens.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: isHovered.value
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: theme.colorScheme.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              // 封面图片
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius.sm),
                child: Container(
                  width: 56,
                  height: 80,
                  color: theme.colorScheme.imagePlaceholder,
                  child: coverPath != null
                      ? ExtendedImage.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        )
                      : Icon(Icons.broken_image, color: theme.colorScheme.iconSecondary),
                ),
              ),
              SizedBox(width: tokens.spacing.lg),

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
                        fontSize: tokens.text.bodyMd,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.xs - 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.subtleTagBackground,
                            borderRadius: BorderRadius.circular(tokens.radius.xs),
                            border: Border.all(color: theme.colorScheme.borderSubtle),
                          ),
                          child: Text(
                            comic.resourceType.name,
                            style: TextStyle(
                              fontSize: tokens.text.labelXs - 1,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: tokens.spacing.md),
                        Text(
                          '${pageCount}p',
                          style: TextStyle(
                            fontSize: tokens.text.labelXs,
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
