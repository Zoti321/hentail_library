import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('monorepo layout', () {
    late Directory repoRoot;

    setUp(() {
      // app/test → repo root
      repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..')));
    });

    test('Flutter app lives under app/', () {
      expect(Directory(p.join(repoRoot.path, 'app', 'lib')).existsSync(), isTrue);
      expect(File(p.join(repoRoot.path, 'app', 'pubspec.yaml')).existsSync(), isTrue);
      expect(Directory(p.join(repoRoot.path, 'lib')).existsSync(), isFalse);
      expect(File(p.join(repoRoot.path, 'pubspec.yaml')).existsSync(), isFalse);
    });

    test('repo root keeps collaboration docs', () {
      expect(File(p.join(repoRoot.path, 'CONTEXT.md')).existsSync(), isTrue);
      expect(Directory(p.join(repoRoot.path, 'docs')).existsSync(), isTrue);
      expect(Directory(p.join(repoRoot.path, '.github')).existsSync(), isTrue);
    });

    test('core/ placeholder exists for upcoming Rust workspace', () {
      expect(Directory(p.join(repoRoot.path, 'core')).existsSync(), isTrue);
    });
  });

  group('app/lib top-level layout', () {
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
