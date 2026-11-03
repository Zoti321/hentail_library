import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('bootstrap/di 不再包含 deps 与 services 遗留桶', () {
    final Directory diDir = Directory(
      p.join('lib', 'features', 'bootstrap', 'di'),
    );
    final List<String> names = diDir
        .listSync()
        .whereType<File>()
        .map((File f) => p.basename(f.path))
        .toList();

    expect(names, isNot(contains('deps.dart')));
    expect(names, isNot(contains('services.dart')));
  });
}
