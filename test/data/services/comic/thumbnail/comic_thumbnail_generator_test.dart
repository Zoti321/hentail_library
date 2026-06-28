import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_generator.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

void main() {
  group('generateComicThumbnailJpegOffMainUi', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hl_thumb_test_');
      final File fixture = File(
        'test/fixtures/thumbnail_bug/grayscale_cover.png',
      );
      final File cover = File('${tempDir.path}/01.png');
      await cover.writeAsBytes(await fixture.readAsBytes());
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('grayscale PNG cover keeps balanced RGB in JPEG thumbnail', () async {
      final Uint8List? thumbnail = await generateComicThumbnailJpegOffMainUi(
        path: tempDir.path,
        type: ResourceType.dir,
      );
      expect(thumbnail, isNotNull);

      final img.Image? decoded = img.decodeImage(thumbnail!);
      expect(decoded, isNotNull);

      final img.Pixel center = decoded!.getPixel(
        decoded.width ~/ 2,
        decoded.height ~/ 2,
      );
      expect(
        center.g,
        equals(center.r),
        reason: 'grayscale source must expand to RGB before JPEG encode',
      );
      expect(center.b, equals(center.r));
    });
  });
}
