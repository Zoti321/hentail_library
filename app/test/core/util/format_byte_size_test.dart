import 'package:hentai_library/core/util/format_byte_size.dart';
import 'package:test/test.dart';

void main() {
  group('formatByteSizeBin1024', () {
    test('zero and negative', () {
      expect(formatByteSizeBin1024(0), '0 B');
      expect(formatByteSizeBin1024(-1), '0 B');
    });

    test('scales through units', () {
      expect(formatByteSizeBin1024(512), '512 B');
      expect(formatByteSizeBin1024(1536), '1.50 KB');
      expect((1024 * 1024).toReadableSize(), '1.00 MB');
    });
  });
}
