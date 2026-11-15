import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('composition keeps named assembly groups', () {
    final Directory diDir = Directory(p.join('lib', 'composition'));
    final List<String> names = diDir
        .listSync()
        .whereType<File>()
        .map((File f) => p.basename(f.path))
        .toList();

    expect(names, isNot(contains('deps.dart')));
    expect(names, isNot(contains('services.dart')));
  });
}
