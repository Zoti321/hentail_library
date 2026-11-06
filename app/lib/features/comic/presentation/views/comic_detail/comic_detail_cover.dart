import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/di/comic_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// MD3E 漫画详情封面：沿用生产封面加载（[comicCoverProvider]），填充到 [AppComicDetailCover] 容器内。
class ComicDetailCover extends ConsumerWidget {
  const ComicDetailCover({super.key, required this.comicId});

  final String comicId;

  static const double _aspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
        .read(comicCoverProvider(comicId).notifier)
        .ensureLoaded(priority: ThumbnailPriority.critical);
    final ComicCoverState state = ref.watch(comicCoverProvider(comicId));

    return AdaptiveComicCover(
      coverDisplay: comicCoverSourceOrPrevious(state),
      containerAspectRatio: _aspectRatio,
      backgroundColor: Colors.white,
      showShadow: false,
      placeholder: _placeholder(state),
      errorPlaceholder: _placeholder(state),
      onDecodeError: () {
        ref.read(comicCoverProvider(comicId).notifier).markDecodeError();
      },
    );
  }

  Widget _placeholder(ComicCoverState state) {
    return switch (state) {
      ComicCoverError() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: ComicCoverPlaceholderKind.error,
      ),
      ComicCoverNoCover() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: ComicCoverPlaceholderKind.noCover,
      ),
      _ => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: ComicCoverPlaceholderKind.loading,
      ),
    };
  }
}
