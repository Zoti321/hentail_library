import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 根据 [ComicCoverState] 渲染封面区域（卡片宽高比 2:3）。
class ComicCoverContent extends ConsumerWidget {
  const ComicCoverContent({
    super.key,
    required this.comicId,
    this.isHover = false,
    this.priority = ThumbnailPriority.high,
  });

  final String comicId;
  final bool isHover;
  final ThumbnailPriority priority;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
        .read(comicCoverProvider(comicId).notifier)
        .ensureLoaded(priority: priority);
    final ComicCoverState state = ref.watch(comicCoverProvider(comicId));

    final Widget content = switch (state) {
      ComicCoverReady(:final data) => _buildImage(
        ref,
        data,
        ComicCoverPlaceholderKind.loading,
      ),
      ComicCoverLoading(:final previous) when previous != null => _buildImage(
        ref,
        previous,
        ComicCoverPlaceholderKind.loading,
      ),
      ComicCoverLoading() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.loading,
      ),
      ComicCoverNoCover() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.noCover,
      ),
      ComicCoverError() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.error,
      ),
    };

    if (!isHover) {
      return content;
    }
    return content
        .animate(target: 1)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildImage(
    WidgetRef ref,
    ComicCoverImage data,
    ComicCoverPlaceholderKind decodeFallbackKind,
  ) {
    return AppComicImage(
      filePath: data.filePath,
      memoryBytes: data.memoryBytes,
      fit: BoxFit.cover,
      placeholder: ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: decodeFallbackKind,
      ),
      errorPlaceholder: ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.error,
      ),
      onDecodeError: () {
        ref.read(comicCoverProvider(comicId).notifier).markDecodeError();
      },
    );
  }
}
