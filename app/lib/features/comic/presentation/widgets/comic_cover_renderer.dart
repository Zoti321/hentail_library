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
    this.fit,
    this.alignment = Alignment.center,
    this.onDecodeError,
    this.onRetry,
  });

  final ComicCoverState state;
  final ComicCoverPaintVariant variant;

  /// Non-null forces fit (e.g. banner [BoxFit.cover]); null enables soft-crop.
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final VoidCallback? onDecodeError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ComicCoverPaintVariant.card => _CardCoverBody(
        state: state,
        fit: fit,
        alignment: alignment,
        onDecodeError: onDecodeError,
        onRetry: onRetry,
      ),
      ComicCoverPaintVariant.detail => _DetailCoverBody(
        state: state,
        onDecodeError: onDecodeError,
        onRetry: onRetry,
      ),
    };
  }
}

class _CardCoverBody extends StatelessWidget {
  const _CardCoverBody({
    required this.state,
    required this.fit,
    required this.alignment,
    required this.onDecodeError,
    required this.onRetry,
  });

  final ComicCoverState state;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final VoidCallback? onDecodeError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
      ComicCoverError() => _RetryablePlaceholder(
        onRetry: onRetry,
        child: const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.card,
          kind: ComicCoverPlaceholderKind.error,
        ),
      ),
    };
  }
}

class _DetailCoverBody extends StatelessWidget {
  const _DetailCoverBody({
    required this.state,
    required this.onDecodeError,
    required this.onRetry,
  });

  final ComicCoverState state;
  final VoidCallback? onDecodeError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ComicCoverSource? source = comicCoverSourceOrPrevious(state);
    final ComicCoverPlaceholderKind kind = switch (state) {
      ComicCoverError() => ComicCoverPlaceholderKind.error,
      ComicCoverNoCover() => ComicCoverPlaceholderKind.noCover,
      ComicCoverReady() ||
      ComicCoverLoading() => ComicCoverPlaceholderKind.loading,
    };
    final Widget placeholder = ComicCoverPlaceholder(
      variant: ComicCoverPlaceholderVariant.detail,
      kind: kind,
    );
    return AdaptiveComicCover(
      coverDisplay: source,
      containerAspectRatio: 2 / 3,
      showShadow: false,
      gaplessPlayback: true,
      placeholder: placeholder,
      errorPlaceholder: state is ComicCoverError
          ? _RetryablePlaceholder(onRetry: onRetry, child: placeholder)
          : placeholder,
      onDecodeError: onDecodeError,
    );
  }
}

/// 有重试回调时整体可点；否则原样返回占位图。
class _RetryablePlaceholder extends StatelessWidget {
  const _RetryablePlaceholder({required this.child, required this.onRetry});

  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
