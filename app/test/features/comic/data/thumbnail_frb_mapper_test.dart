import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/data/thumbnail_frb_mapper.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/thumbnail_event.dart';
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
    final ThumbnailReady ready = mapped as ThumbnailReady;
    expect(ready.comicId, 'comic-1');
    expect(ready.thumbnail, isNull);
  });

  test('mapThumbnailEvent maps ready event with embedded thumbnail bytes', () {
    final ThumbnailEvent mapped = mapThumbnailEvent(
      rust.ThumbnailEventDto.ready(
        comicId: 'comic-2',
        thumbnail: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );

    expect(mapped, isA<ThumbnailReady>());
    final ThumbnailReady ready = mapped as ThumbnailReady;
    expect(ready.comicId, 'comic-2');
    expect(ready.thumbnail, <int>[1, 2, 3]);
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
