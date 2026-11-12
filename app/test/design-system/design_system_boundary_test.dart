import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// Design System 层出边门禁（ADR-0044 / #495 S0）。
///
/// 零允许清单：本层从第一天起即零例外。
const String _layerRoot = 'design-system';

/// 严禁的出边目标前缀（业务、DI、数据与 `shared/ui` 复合层）。
const List<String> _forbiddenTargetPrefixes = <String>[
  'features/',
  'shared/domain/',
  'shared/presentation/providers/',
  'infrastructure/',
  'shared/ui/',
];

/// 唯一允许的层外依赖前缀。
const List<String> _allowedTargetPrefixes = <String>['core/'];

final RegExp _layerEdgeRe = RegExp(
  r"^\s*(?:import|export)\s+'([^']+)'",
  multiLine: true,
);

/// 解析一条 import/export 到 lib 相对 POSIX 路径；非本仓包返回 null。
String? resolveLayerTarget(String uri, String sourceRel) {
  const String packagePrefix = 'package:hentai_library/';
  if (uri.startsWith(packagePrefix)) {
    return p.posix.normalize(uri.substring(packagePrefix.length));
  }
  if (uri.contains(':')) {
    return null;
  }
  return p.posix.normalize(p.posix.join(p.posix.dirname(sourceRel), uri));
}

typedef _Edge = ({String rel, String uri, String? target});

void main() {
  late Directory libDir;
  late List<File> layerFiles;
  late List<_Edge> edges;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    final Directory layerDir = Directory(p.join(libDir.path, _layerRoot));
    layerFiles = layerDir.existsSync()
        ? dartFilesUnder(layerDir).toList()
        : <File>[];
    edges = <_Edge>[];
    for (final File file in layerFiles) {
      final String rel = libRelativePosixPath(libDir, file);
      final String source = file.readAsStringSync();
      for (final RegExpMatch match in _layerEdgeRe.allMatches(source)) {
        final String uri = match.group(1)!;
        edges.add((rel: rel, uri: uri, target: resolveLayerTarget(uri, rel)));
      }
    }
  });

  test('classifyLibPath treats design-system as shared (inherits R13)', () {
    expect(classifyLibPath('design-system/theme/theme.dart'), 'shared');
    expect(classifyLibPath('design-system/design_system.dart'), 'shared');
  });

  test('no edge into features/ or shared domain·di·data·ui', () {
    final List<String> offenders = <String>[
      for (final _Edge edge in edges)
        if (edge.target != null &&
            _forbiddenTargetPrefixes.any(edge.target!.startsWith))
          '${edge.rel} -> ${edge.uri}',
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'design-system 不得依赖业务层或 shared/ui（ADR-0044）：\n'
          '${offenders.join('\n')}',
    );
  });

  test('edges stay inside the layer or core/', () {
    final List<String> offenders = <String>[
      for (final _Edge edge in edges)
        if (edge.target != null &&
            !edge.target!.startsWith('$_layerRoot/') &&
            !_allowedTargetPrefixes.any(edge.target!.startsWith))
          '${edge.rel} -> ${edge.uri}',
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'design-system 只允许 core/** 与层内路径：\n'
          '${offenders.join('\n')}',
    );
  });

  test('layer files are not export-only shims', () {
    final List<String> offenders = <String>[
      for (final File file in layerFiles)
        if (libRelativePosixPath(libDir, file) !=
                '$_layerRoot/design_system.dart' &&
            isStranglerExportOnlyShim(file.readAsStringSync()))
          libRelativePosixPath(libDir, file),
    ];
    expect(offenders, isEmpty, reason: '删除 export-only shim：$offenders');
  });
}
