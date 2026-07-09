import 'package:hentai_library/core/logging/log_redactor.dart';
import 'package:test/test.dart';

void main() {
  group('redactLogText', () {
    test('replaces home directory with <HOME>', () {
      const String home = r'C:\Users\alice';
      const String input =
          r'open path=C:\Users\alice\comics\book.zip comic_id=abc';
      final String result = redactLogText(input, homeDirectory: home);
      expect(result, contains('<HOME>'));
      expect(result, isNot(contains(r'C:\Users\alice')));
    });

    test('redacts windows paths to basename', () {
      const String input = r'failed path=D:\archive\nested\page.jpg';
      final String result = redactLogText(input);
      expect(result, contains('page.jpg'));
      expect(result, isNot(contains(r'D:\archive')));
    });

    test('hashes comic_id values', () {
      const String input = 'reader opened comic_id=my-secret-comic-id';
      final String result = redactLogText(input);
      expect(result, contains('comic_id=${hashBusinessId('my-secret-comic-id')}'));
      expect(result, isNot(contains('my-secret-comic-id')));
    });

    test('hashBusinessId is stable and eight chars', () {
      expect(hashBusinessId('same'), hashBusinessId('same'));
      expect(hashBusinessId('value').length, 8);
    });
  });
}
