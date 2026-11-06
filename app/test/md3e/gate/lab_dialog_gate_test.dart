import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 原 `lib/md3e` 搬迁后的 MD3E 代码所在目录（#413）。Baseline 的 `shared/ui/widgets`
/// 与 feature 内既有代码不在本门禁范围内。
const List<String> roots = <String>[
  'lib/shared/ui/patterns',
  'lib/shared/ui/shell',
];

List<File> dartFiles() {
  final List<File> files = <File>[];
  for (final String root in roots) {
    final Directory dir = Directory(root);
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity);
      }
    }
  }
  return files;
}

void main() {
  test('MD3E lib 不使用 Material showDialog / Dialog 壳', () {
    final RegExp showDialogPattern = RegExp(r'\bshowDialog\s*<');
    final RegExp materialDialogPattern = RegExp(r'return\s+Dialog\s*\(');

    final List<String> violations = <String>[];
    for (final File file in dartFiles()) {
      final String content = file.readAsStringSync();
      if (showDialogPattern.hasMatch(content)) {
        violations.add('${file.path}: showDialog');
      }
      if (materialDialogPattern.hasMatch(content)) {
        violations.add('${file.path}: Dialog(');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Lab 对话框应经 LabDialogPresenter / M3EDialog：\n${violations.join('\n')}',
    );
  });
}
