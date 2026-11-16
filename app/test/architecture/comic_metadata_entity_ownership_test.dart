import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// `comic_metadata` 模块门禁（ADR-0048）。
///
/// 1. 实体归属：`Author` / `AuthorDetail` / `Tag` 真源在
///    `features/comic_metadata/domain/`；`shared/**` 不得再引用。
/// 2. 旧模块路径不得复活：`named_metadata` 目录与 import 面均为零。
void main() {
  late Directory appDir;
  late Directory libDir;

  setUp(() {
    appDir = Directory.current;
    libDir = Directory(p.join(appDir.path, 'lib'));
  });

  group('comic_metadata 实体归属（ADR-0048）', () {
    test('shared kernel 不含三个实体文件', () {
      const List<String> forbiddenPaths = <String>[
        'shared/domain/models/entity/comic/author.dart',
        'shared/domain/models/entity/comic/author_detail.dart',
        'shared/domain/models/entity/comic/tag.dart',
      ];
      final List<String> present = <String>[
        for (final String rel in forbiddenPaths)
          if (File(p.joinAll(<String>[libDir.path, ...rel.split('/')]))
              .existsSync())
            rel,
      ];
      expect(
        present,
        isEmpty,
        reason:
            'Author / AuthorDetail / Tag 真源在 features/comic_metadata/domain/'
            '（ADR-0048）；shared 保留 AuthorRef / AuthorDetailPort 等契约：\n'
            '${present.join('\n')}',
      );
    });

    test('shared/** 不引用三个实体类型（注释除外）', () {
      final List<String> offenders = <String>[];
      for (final File file in dartFilesUnder(
        Directory(p.join(libDir.path, 'shared')),
      )) {
        if (isGeneratedDartFile(file.path)) {
          continue;
        }
        final String code = _stripDartComments(file.readAsStringSync());
        if (_entityTypeRe.hasMatch(code)) {
          offenders.add(libRelativePosixPath(libDir, file));
        }
      }
      offenders.sort();
      expect(
        offenders,
        isEmpty,
        reason:
            '实体已迁入 features/comic_metadata（ADR-0048）；'
            'shared 只保留 AuthorRef / AuthorDetailPort 等跨模块契约：\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('旧模块路径不得复活（ADR-0048）', () {
    test('features/named_metadata 目录不存在', () {
      expect(
        Directory(p.join(libDir.path, 'features', 'named_metadata'))
            .existsSync(),
        isFalse,
        reason: '模块已更名为 comic_metadata（ADR-0048）',
      );
    });

    test('代码中不存在 named_metadata import / export', () {
      final List<String> offenders = <String>[];
      for (final String rootName in <String>['lib', 'test', 'widgetbook']) {
        final Directory root = Directory(p.join(appDir.path, rootName));
        if (!root.existsSync()) {
          continue;
        }
        for (final File file in dartFilesUnder(root)) {
          if (_oldModuleRe.hasMatch(file.readAsStringSync())) {
            offenders.add(
              p.posix.joinAll(
                p.split(p.relative(file.path, from: appDir.path)),
              ),
            );
          }
        }
      }
      offenders.sort();
      expect(
        offenders,
        isEmpty,
        reason:
            '${_oldModuleRe.pattern} 已废弃（ADR-0048），请改用 '
            'features/comic_metadata/：\n${offenders.join('\n')}',
      );
    });
  });
}

final RegExp _entityTypeRe = RegExp(r'\b(?:Author|AuthorDetail|Tag)\b');

/// 旧模块 import 前缀（拆开书写，避免本测试自身被自己的扫描命中）。
final RegExp _oldModuleRe = RegExp(
  'package:hentai_library/features/named_'
  'metadata/',
);

String _stripDartComments(String source) {
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}
