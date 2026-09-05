import 'package:hentai_library/domain/models/value_objects/comic_language.dart';
import 'package:test/test.dart';

void main() {
  const Map<String, String> zhLabels = <String, String>{
    ComicLanguageNames.chinese: '中文',
    ComicLanguageNames.japanese: '日语',
    ComicLanguageNames.english: '英语',
    ComicLanguageNames.korean: '韩语',
    ComicLanguageNames.spanish: '西班牙语',
    ComicLanguageNames.other: '其他',
  };

  group('formatComicLanguagesDisplay', () {
    test('joins localized closed-set names with pipe', () {
      expect(
        formatComicLanguagesDisplay(<String>[
          'Chinese',
          'Japanese',
        ], closedLabels: zhLabels),
        '中文|日语',
      );
    });

    test('passes unknown tokens through verbatim', () {
      expect(
        formatComicLanguagesDisplay(<String>[
          'Chinese',
          'Esperanto',
        ], closedLabels: zhLabels),
        '中文|Esperanto',
      );
    });

    test('empty list yields empty string', () {
      expect(
        formatComicLanguagesDisplay(<String>[], closedLabels: zhLabels),
        '',
      );
    });
  });
}
