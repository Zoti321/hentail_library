import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// Comic 实体归属门禁（ADR-0041）。
///
/// Comic 真源在 `features/comic/domain/`；`shared/**` 不得再出现 Comic 实体
/// 类型引用（注释除外）。跨模块只经 `features/comic/public/**` thin re-export。
void main() {
  late Directory libDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test('shared kernel 不含 Comic 实体文件', () {
    final File file = File(
      p.join(
        libDir.path,
        'shared',
        'domain',
        'models',
        'entity',
        'comic',
        'comic.dart',
      ),
    );
    expect(
      file.existsSync(),
      isFalse,
      reason: 'Comic 实体真源在 features/comic/domain/comic.dart（ADR-0041）',
    );
  });

  test('shared/** 不引用 Comic 实体类型（注释除外）', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(
      Directory(p.join(libDir.path, 'shared')),
    )) {
      if (isGeneratedDartFile(file.path)) {
        continue;
      }
      final String code = _stripDartComments(file.readAsStringSync());
      if (_comicTypeRe.hasMatch(code)) {
        offenders.add(libRelativePosixPath(libDir, file));
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'Comic 实体已迁入 features/comic（ADR-0041）；shared 只保留共享内核：\n'
          '${offenders.join('\n')}',
    );
  });
}

final RegExp _comicTypeRe = RegExp(r'\bComic\b');

String _stripDartComments(String source) {
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}
