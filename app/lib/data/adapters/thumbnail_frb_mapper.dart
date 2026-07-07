import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart' as rust;

rust.ThumbnailPriorityDto mapThumbnailPriority(ThumbnailPriority priority) {
  return switch (priority) {
    ThumbnailPriority.critical => rust.ThumbnailPriorityDto.critical,
    ThumbnailPriority.high => rust.ThumbnailPriorityDto.high,
    ThumbnailPriority.low => rust.ThumbnailPriorityDto.low,
  };
}

ThumbnailEvent mapThumbnailEvent(rust.ThumbnailEventDto event) {
  return switch (event) {
    rust.ThumbnailEventDto_Ready(:final String comicId) => ThumbnailReady(
      comicId,
    ),
    rust.ThumbnailEventDto_Progress(
      :final int done,
      :final int total,
      :final int failed,
    ) =>
      ThumbnailProgress(done: done, total: total, failed: failed),
  };
}
