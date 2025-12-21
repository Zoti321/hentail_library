import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/util/utils.dart';

void main() {
  group('generateComicId', () {
    test('same input produces same hash', () {
      final a = generateComicId('Title', coverUrl: 'url', description: 'desc');
      final b = generateComicId('Title', coverUrl: 'url', description: 'desc');
      expect(a, b);
    });

    test('different input produces different hash', () {
      final a = generateComicId('Title1');
      final b = generateComicId('Title2');
      expect(a, isNot(b));
    });

    test('optional params change result', () {
      final withCover = generateComicId('T', coverUrl: 'c');
      final without = generateComicId('T');
      expect(withCover, isNot(without));
    });
  });

  group('generateChapterId', () {
    test('same input produces same hash', () {
      final a = generateChapterId('Comic', '/path', 10, 1);
      final b = generateChapterId('Comic', '/path', 10, 1);
      expect(a, b);
    });

    test('different input produces different hash', () {
      final a = generateChapterId('Comic', '/path', 10, 1);
      final b = generateChapterId('Comic', '/path', 10, 2);
      expect(a, isNot(b));
    });
  });
}
