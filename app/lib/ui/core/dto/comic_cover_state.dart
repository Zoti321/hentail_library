import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';

/// 漫画封面展示状态（Provider 层消费）。
sealed class ComicCoverState {
  const ComicCoverState();
}

/// 加载中；[previous] 用于切页/重排时保留上一帧。
final class ComicCoverLoading extends ComicCoverState {
  const ComicCoverLoading({this.previous});

  final ComicCoverImage? previous;
}

final class ComicCoverReady extends ComicCoverState {
  const ComicCoverReady(this.data);

  final ComicCoverImage data;
}

/// 无可用封面（含缩略图生成中）。
final class ComicCoverNoCover extends ComicCoverState {
  const ComicCoverNoCover();
}

/// 读取或资源异常。
final class ComicCoverError extends ComicCoverState {
  const ComicCoverError({this.cause});

  final Object? cause;
}

/// 从 [ComicCoverState] 提取可渲染的封面图像（ready 或 loading 的 previous）。
ComicCoverImage? comicCoverImageOrPrevious(ComicCoverState state) {
  return switch (state) {
    ComicCoverReady(:final data) => data,
    ComicCoverLoading(:final previous) => previous,
    ComicCoverNoCover() || ComicCoverError() => null,
  };
}
