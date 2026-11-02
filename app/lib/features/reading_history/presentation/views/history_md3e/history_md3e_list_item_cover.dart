import 'package:flutter/material.dart';
import 'package:hentai_library/shared/di/comic_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 阅读历史 MD3E 列表行封面（沿用 [comicCoverProvider]）。
class HistoryMd3eListItemCover extends ConsumerWidget {
  const HistoryMd3eListItemCover({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
        .read(comicCoverProvider(comicId).notifier)
        .bumpPriority(ThumbnailPriority.high);
    final ComicCoverState state = ref.watch(comicCoverProvider(comicId));

    return AdaptiveComicCover(
      coverDisplay: comicCoverSourceOrPrevious(state),
      containerAspectRatio: 2 / 3,
      backgroundColor: Colors.transparent,
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
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.error,
      ),
      ComicCoverNoCover() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.noCover,
      ),
      _ => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.loading,
      ),
    };
  }
}
