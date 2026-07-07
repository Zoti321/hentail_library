/// 缩略图后台生成事件（领域层，不含 FRB 类型）。
sealed class ThumbnailEvent {
  const ThumbnailEvent();
}

final class ThumbnailReady extends ThumbnailEvent {
  const ThumbnailReady(this.comicId);

  final String comicId;
}

final class ThumbnailProgress extends ThumbnailEvent {
  const ThumbnailProgress({
    required this.done,
    required this.total,
    required this.failed,
  });

  final int done;
  final int total;
  final int failed;
}
