import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('md3e lib 不使用 Material showDialog / Dialog 壳', () {
    final Directory md3eLib = Directory('lib/md3e');
    expect(md3eLib.existsSync(), isTrue);

    final RegExp showDialogPattern = RegExp(r'\bshowDialog\s*<');
    final RegExp materialDialogPattern = RegExp(r'return\s+Dialog\s*\(');

    final List<String> violations = <String>[];
    for (final FileSystemEntity entity in md3eLib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String content = entity.readAsStringSync();
      if (showDialogPattern.hasMatch(content)) {
        violations.add('${entity.path}: showDialog');
      }
      if (materialDialogPattern.hasMatch(content)) {
        violations.add('${entity.path}: Dialog(');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Lab 对话框应经 Md3eLabDialogPresenter / M3EDialog：\n${violations.join('\n')}',
    );
  });
}
