import 'dart:typed_data';

/// 缩略图后台生成事件（领域层，不含 FRB 类型）。
sealed class ThumbnailEvent {
  const ThumbnailEvent();
}

final class ThumbnailReady extends ThumbnailEvent {
  const ThumbnailReady(this.comicId, {this.thumbnail});

  final String comicId;

  /// 若 Rust 已附带 JPEG 字节则非空，可免二次 find。
  final Uint8List? thumbnail;
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
