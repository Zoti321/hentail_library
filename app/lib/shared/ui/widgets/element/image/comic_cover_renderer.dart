import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';

/// Shared cover paint for catalog card vs detail chrome.
enum ComicCoverPaintVariant { card, detail }

/// Maps [ComicCoverState] → letterboxed image / placeholder for card or detail.
class ComicCoverRenderer extends StatelessWidget {
  const ComicCoverRenderer({
    super.key,
    required this.state,
    required this.variant,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.onDecodeError,
    this.onRetry,
  });

  final ComicCoverState state;
  final ComicCoverPaintVariant variant;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final VoidCallback? onDecodeError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ComicCoverPaintVariant.card => _buildCard(),
      ComicCoverPaintVariant.detail => _buildDetail(),
    };
  }

  Widget _buildCard() {
    return switch (state) {
      ComicCoverReady(:final data) => CardLetterboxedCoverImage(
        cover: data,
        fit: fit,
        alignment: alignment,
        onDecodeError: onDecodeError,
      ),
      ComicCoverLoading(:final previous) when previous != null =>
        CardLetterboxedCoverImage(
          cover: previous,
          fit: fit,
          alignment: alignment,
          onDecodeError: onDecodeError,
        ),
      ComicCoverLoading() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.loading,
      ),
      ComicCoverNoCover() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.noCover,
      ),
      ComicCoverError() => _retryablePlaceholder(
        const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.card,
          kind: ComicCoverPlaceholderKind.error,
        ),
      ),
    };
  }

  Widget _buildDetail() {
    final ComicCoverSource? source = comicCoverSourceOrPrevious(state);
    final Widget placeholder = _detailPlaceholder(state);
    return AdaptiveComicCover(
      coverDisplay: source,
      containerAspectRatio: 2 / 3,
      backgroundColor: Colors.white,
      showShadow: false,
      gaplessPlayback: true,
      placeholder: placeholder,
      errorPlaceholder: placeholder,
      onDecodeError: onDecodeError,
    );
  }

  Widget _detailPlaceholder(ComicCoverState state) {
    final ComicCoverPlaceholderKind kind = switch (state) {
      ComicCoverError() => ComicCoverPlaceholderKind.error,
      ComicCoverNoCover() => ComicCoverPlaceholderKind.noCover,
      _ => ComicCoverPlaceholderKind.loading,
    };
    final Widget placeholder = ComicCoverPlaceholder(
      variant: ComicCoverPlaceholderVariant.detail,
      kind: kind,
    );
    if (state is ComicCoverError) {
      return _retryablePlaceholder(placeholder);
    }
    return placeholder;
  }

  Widget _retryablePlaceholder(Widget child) {
    final VoidCallback? retry = onRetry;
    if (retry == null) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: retry,
      child: child,
    );
  }
}
