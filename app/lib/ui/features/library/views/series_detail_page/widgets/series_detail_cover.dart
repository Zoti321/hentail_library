import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/ui/providers.dart';

class SeriesDetailCover extends ConsumerWidget {
  const SeriesDetailCover({super.key, required this.series});

  final Series series;

  static const double containerAspectRatio = 2 / 3;
  static const double _cornerRadius = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;

    if (coverComicId == null) {
      return AdaptiveComicCover(
        coverDisplay: null,
        containerAspectRatio: containerAspectRatio,
        backgroundColor: Colors.white,
        showShadow: true,
        placeholder: const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.detail,
          kind: ComicCoverPlaceholderKind.noCover,
        ),
        errorPlaceholder: const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.detail,
          kind: ComicCoverPlaceholderKind.noCover,
        ),
        clipBorderRadius: BorderRadius.circular(_cornerRadius),
      );
    }

    ref
        .read(comicCoverProvider(coverComicId).notifier)
        .ensureLoaded(priority: ThumbnailPriorityDto.critical);
    final ComicCoverState state = ref.watch(comicCoverProvider(coverComicId));

    return AdaptiveComicCover(
      coverDisplay: comicCoverDisplayDataOrPrevious(state),
      containerAspectRatio: containerAspectRatio,
      backgroundColor: Colors.white,
      showShadow: true,
      placeholder: _buildPlaceholder(state),
      errorPlaceholder: _buildPlaceholder(state),
      clipBorderRadius: BorderRadius.circular(_cornerRadius),
      onDecodeError: () {
        ref.read(comicCoverProvider(coverComicId).notifier).markDecodeError();
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
