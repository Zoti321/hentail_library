import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// Series 实体归属门禁（ADR-0042）。
///
/// Series 真源在 `features/series/domain/`；`shared/**` 不得再出现 Series
/// 实体 / 值对象 / 表单类型（注释与生成文件除外）。跨模块只经 Port / ACK 投影。
void main() {
  late Directory libDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test('shared kernel 不含 Series 实体/VO/表单文件', () {
    const List<String> forbiddenPaths = <String>[
      'shared/domain/models/entity/comic/series.dart',
      'shared/domain/models/entity/comic/series_item.dart',
      'shared/domain/models/value_objects/series_meta_locks.dart',
      'shared/domain/models/value_objects/series_comics_metadata.dart',
      'shared/domain/models/value_objects/series_metadata_form.dart',
      'shared/domain/models/value_objects/form/series_metadata_form.dart',
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
          'Series 实体/VO 真源在 features/series/domain/（ADR-0042）；'
          'shared 只保留跨模块契约：\n${present.join('\n')}',
    );
  });

  test('shared/** 不引用 Series 实体类型（注释除外）', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(
      Directory(p.join(libDir.path, 'shared')),
    )) {
      if (isGeneratedDartFile(file.path)) {
        continue;
      }
      final String code = _stripDartComments(file.readAsStringSync());
      if (_seriesTypeRe.hasMatch(code)) {
        offenders.add(libRelativePosixPath(libDir, file));
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'Series 实体已迁入 features/series（ADR-0042）；'
          'shared 只保留 SeriesReadingContext / SeriesItemMembership / '
          'PersistSeriesItemSortCommand / SeriesCoverSource 等契约：\n'
          '${offenders.join('\n')}',
    );
  });
}

final RegExp _seriesTypeRe = RegExp(r'\bSeries\b');

String _stripDartComments(String source) {
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}
