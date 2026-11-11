import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// 槽位契约门禁（ADR-0042）：`shared/ui/slots/**` 只承载 Flutter + 原始值，
/// 禁止 import `features/**`，实现由 bootstrap 组合根注入。
void main() {
  late Directory slotsDir;

  setUp(() {
    final Directory libDir = Directory(p.join(Directory.current.path, 'lib'));
    slotsDir = Directory(
      p.joinAll(<String>[libDir.path, 'shared', 'ui', 'slots']),
    );
  });

  test('shared/ui/slots/** 不 import features/**', () {
    expect(
      slotsDir.existsSync(),
      isTrue,
      reason: '槽位契约目录缺失：lib/shared/ui/slots（ADR-0042）',
    );
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(slotsDir)) {
      if (isGeneratedDartFile(file.path)) {
        continue;
      }
      final String source = file.readAsStringSync();
      if (_featureUriRe.hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          '槽位契约只允许 Flutter + 原始值，禁止依赖 features/**（ADR-0042）：\n'
          '${offenders.join('\n')}',
    );
  });
}

final RegExp _featureUriRe = RegExp(
  r'''(?:import|export)\s+['"]package:hentai_library/features/''',
);
