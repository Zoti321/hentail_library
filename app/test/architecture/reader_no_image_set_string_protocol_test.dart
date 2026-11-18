import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// ADR-0061: business code must not branch on `image_set:` session-key prefixes.
void main() {
  test('reader lib avoids startsWith(image_set:) business protocol', () {
    final Directory root = Directory(
      p.join('lib', 'features', 'reader'),
    );
    expect(root.existsSync(), isTrue);
    final List<String> offenders = <String>[];
    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (entity.path.contains('.g.dart') ||
          entity.path.contains('.freezed.dart')) {
        continue;
      }
      final String source = entity.readAsStringSync();
      if (source.contains("startsWith('image_set:')") ||
          source.contains('startsWith("image_set:")')) {
        offenders.add(p.normalize(entity.path));
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
