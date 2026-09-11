import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/adapters/thumbnail_frb_mapper.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart' as rust;

void main() {
  test('mapThumbnailPriority maps domain priorities to FRB DTOs', () {
    expect(
      mapThumbnailPriority(ThumbnailPriority.critical),
      rust.ThumbnailPriorityDto.critical,
    );
    expect(
      mapThumbnailPriority(ThumbnailPriority.high),
      rust.ThumbnailPriorityDto.high,
    );
    expect(
      mapThumbnailPriority(ThumbnailPriority.low),
      rust.ThumbnailPriorityDto.low,
    );
  });

  test('mapThumbnailEvent maps ready event to ThumbnailReady', () {
    final ThumbnailEvent mapped = mapThumbnailEvent(
      const rust.ThumbnailEventDto.ready(comicId: 'comic-1'),
    );

    expect(mapped, isA<ThumbnailReady>());
    expect((mapped as ThumbnailReady).comicId, 'comic-1');
  });

  test('mapThumbnailEvent maps progress counters', () {
    final ThumbnailEvent mapped = mapThumbnailEvent(
      const rust.ThumbnailEventDto.progress(done: 2, total: 5, failed: 1),
    );

    expect(mapped, isA<ThumbnailProgress>());
    final ThumbnailProgress progress = mapped as ThumbnailProgress;
    expect(progress.done, 2);
    expect(progress.total, 5);
    expect(progress.failed, 1);
  });
}
