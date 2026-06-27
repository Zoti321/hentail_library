import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('lib/ top-level layout', () {
    test('only canonical directories exist', () {
      final Directory libDir = Directory(p.join(Directory.current.path, 'lib'));
      final Set<String> actualNames = libDir
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => p.basename(d.path))
          .toSet();
      const Set<String> expectedNames = <String>{
        'core',
        'data',
        'domain',
        'ui',
      };
      expect(actualNames, expectedNames);
    });
  });
}
