import 'package:hentai_library/features/reader/presentation/image/page_decode_size_policy.dart';
import 'package:test/test.dart';

void main() {
  group('pageDecodeSizeForSource', () {
    test('keeps source resolution when longest edge is within max-edge', () {
      final PageDecodeSize size = pageDecodeSizeForSource(
        sourceWidth: 4096,
        sourceHeight: 6000,
      );

      expect(size.capped, isFalse);
      expect(size.cacheWidth, isNull);
      expect(size.cacheHeight, isNull);
    });

    test('keeps source resolution when longest edge equals max-edge', () {
      final PageDecodeSize size = pageDecodeSizeForSource(
        sourceWidth: kReaderPageDecodeMaxEdge,
        sourceHeight: 1000,
      );

      expect(size.capped, isFalse);
      expect(size.cacheWidth, isNull);
      expect(size.cacheHeight, isNull);
    });

    test('caps proportionally when width is the long edge over max-edge', () {
      final PageDecodeSize size = pageDecodeSizeForSource(
        sourceWidth: 16384,
        sourceHeight: 8192,
      );

      expect(size.capped, isTrue);
      expect(size.cacheWidth, kReaderPageDecodeMaxEdge);
      expect(size.cacheHeight, 4096);
    });

    test('caps proportionally when height is the long edge over max-edge', () {
      final PageDecodeSize size = pageDecodeSizeForSource(
        sourceWidth: 4000,
        sourceHeight: 12000,
      );

      expect(size.capped, isTrue);
      expect(size.cacheWidth, 2731);
      expect(size.cacheHeight, kReaderPageDecodeMaxEdge);
    });

    test('returns uncapped nulls for non-positive dimensions', () {
      final PageDecodeSize size = pageDecodeSizeForSource(
        sourceWidth: 0,
        sourceHeight: 100,
      );

      expect(size.capped, isFalse);
      expect(size.cacheWidth, isNull);
      expect(size.cacheHeight, isNull);
    });

    test('honors an explicit maxEdge override', () {
      final PageDecodeSize size = pageDecodeSizeForSource(
        sourceWidth: 2000,
        sourceHeight: 1000,
        maxEdge: 1000,
      );

      expect(size.capped, isTrue);
      expect(size.cacheWidth, 1000);
      expect(size.cacheHeight, 500);
    });
  });
}
