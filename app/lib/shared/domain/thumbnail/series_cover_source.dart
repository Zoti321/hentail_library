import 'dart:typed_data';

/// 系列封面解析结果：自定义缩略图优先，否则回退到成员漫画封面。
sealed class SeriesCoverSource {
  const SeriesCoverSource();
}

class SeriesCoverCustomThumbnail extends SeriesCoverSource {
  const SeriesCoverCustomThumbnail(this.thumbnail);
  final Uint8List thumbnail;
}

class SeriesCoverFallbackComic extends SeriesCoverSource {
  const SeriesCoverFallbackComic(this.comicId);
  final String comicId;
}

class SeriesCoverMissing extends SeriesCoverSource {
  const SeriesCoverMissing();
}
