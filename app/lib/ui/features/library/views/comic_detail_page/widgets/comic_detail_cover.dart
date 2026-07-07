import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicDetailCover extends ConsumerWidget {
  const ComicDetailCover({super.key, required this.comic});

  final Comic comic;

  static const double containerAspectRatio = 2 / 3;
  static const double _cornerRadius = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String comicId = comic.comicId;
    ref
        .read(comicCoverProvider(comicId).notifier)
        .ensureLoaded(priority: ThumbnailPriority.critical);
    final ComicCoverState state = ref.watch(comicCoverProvider(comicId));

    return AdaptiveComicCover(
      coverDisplay: comicCoverImageOrPrevious(state),
      containerAspectRatio: containerAspectRatio,
      backgroundColor: Colors.white,
      showShadow: true,
      placeholder: _buildPlaceholder(state),
      errorPlaceholder: _buildPlaceholder(state),
      clipBorderRadius: BorderRadius.circular(_cornerRadius),
      onDecodeError: () {
        ref.read(comicCoverProvider(comicId).notifier).markDecodeError();
      },
    );
  }

  Widget _buildPlaceholder(ComicCoverState state) {
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
