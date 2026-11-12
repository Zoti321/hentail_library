import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// 跨模块边界门禁（ADR-0034 / ADR-0036 / #488）。
///
/// 与旧 `test/gate/import_boundary_test.dart` 并行：本文件**同时扫描
/// `import` 与 `export`**，因为 bridge 形式的 `export` 后门曾让 public 环
/// 在旧门禁下全绿。
///
/// 范围内模块（`comic` / `series` / `library_browse`）零 baseline；
/// 范围外模块继续沿用 `test/gate/import_boundary_baseline.json` 的 shrink-only
/// 棘轮，直到各自的收敛 PR 完成。
const Set<String> _kInScopeModules = <String>{
  'comic',
  'series',
  'library_browse',
};

/// 显式禁止边：任何 import/export 都算违规（不看是否 public）。
///
/// `app_settings ↛ {reader, library_browse, comic, series, metadata_backup}`
/// 由 ADR-0046 引入：设置模块只认识持久化原语，偏好语义归 owner 模块。
///
/// `comic_metadata ↛ {comic, library_browse, series, reader}`
/// 由 ADR-0048 引入：元数据字典是 owner，只能被编辑面消费，不得反向依赖。
const Map<String, Set<String>> _kForbiddenEdges = <String, Set<String>>{
  'comic': <String>{'library_browse', 'series', 'reader'},
  'series': <String>{'library_browse', 'reader'},
  'reader': <String>{'comic'},
  'comic_metadata': <String>{'comic', 'library_browse', 'series', 'reader'},
  'app_settings': <String>{
    'reader',
    'library_browse',
    'comic',
    'series',
    'metadata_backup',
  },
};

/// R12 白名单条目数上限：只允许缩小。
const int _kR12AllowlistRatchet = 41;

/// 禁止边存量（只减不增）：reader → comic 的 public 读取面在 #488 前已存在，
/// 归 reader 模块收敛 PR 处理；新边一律失败。
const Set<String> _kForbiddenBaseline = <String>{
  'X1|reader|comic|features/reader/presentation/view_models/reader_cover_editor_notifier.dart|package:hentai_library/features/comic/public.dart',
};

final RegExp _edgeUriRe = RegExp(
  r"^\s*(?:import|export)\s+'package:hentai_library/([^']+)'",
  multiLine: true,
);

typedef _Edge = ({
  String source,
  String target,
  String file,
  String uri,
  bool deep,
  bool crossPresentation,
});

void main() {
  late Directory libDir;
  late List<_Edge> edges;
  late Set<String> baseline;

  setUpAll(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    edges = _collectEdges(libDir);
    baseline = _loadBaseline();
    _architectureBaseline = _loadJson(
      p.join(Directory.current.path, 'test', 'architecture', 'baseline.json'),
    );
  });

  test('M1：范围内模块跨模块 import/export 只走 public', () {
    final List<String> offenders = <String>[];
    for (final _Edge edge in edges) {
      if (!_kInScopeModules.contains(edge.source) ||
          !_kInScopeModules.contains(edge.target)) {
        continue;
      }
      if (edge.deep) {
        offenders.add(_format(edge, 'deep 跨模块引用'));
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason: '范围内模块只允许 public 面（零 baseline）：\n${offenders.join('\n')}',
    );
  });

  test('M1/M2：范围外模块跨模块边只减不增（shrink-only）', () {
    final Set<String> newViolations = <String>{};
    for (final _Edge edge in edges) {
      if (!isProductModule(edge.source) ||
          edge.source == 'bootstrap' ||
          edge.source == 'shared' ||
          edge.source == edge.target) {
        continue;
      }
      if (_kInScopeModules.contains(edge.source) ||
          _kInScopeModules.contains(edge.target)) {
        continue;
      }
      if (edge.deep) {
        final String key = _key('M1', edge);
        if (!baseline.contains(key)) {
          newViolations.add(key);
        }
      }
      if (edge.crossPresentation) {
        final String key = _key('M2', edge);
        if (!baseline.contains(key)) {
          newViolations.add(key);
        }
      }
    }
    expect(
      newViolations,
      isEmpty,
      reason:
          '新增跨模块深引用（请改 owner public，或先扩 ADR-0034 面）：\n'
          '${(newViolations.toList()..sort()).join('\n')}',
    );
  });

  test('共享内核不得反向依赖产品模块（范围内零 baseline）', () {
    final List<String> offenders = <String>[];
    for (final _Edge edge in edges) {
      if (edge.source != 'shared') {
        continue;
      }
      if (!isProductModule(edge.target)) {
        continue;
      }
      final bool kernelScope =
          edge.file.startsWith('shared/domain/') ||
          edge.file.startsWith('core/');
      if (kernelScope && _kInScopeModules.contains(edge.target)) {
        offenders.add(_format(edge, 'shared 内核 → ${edge.target}'));
        continue;
      }
      final String key = _key('R13', edge);
      if (!baseline.contains(key) && !_architectureBaseline.contains(key)) {
        offenders.add(_format(edge, '新增 R13'));
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'shared 不得 import/export features（ADR-0035）：\n${offenders.join('\n')}',
    );
  });

  test('显式禁止边表（comic/series/reader/comic_metadata）', () {
    final List<String> offenders = <String>[];
    for (final _Edge edge in edges) {
      final Set<String>? forbidden = _kForbiddenEdges[edge.source];
      if (forbidden == null || !forbidden.contains(edge.target)) {
        continue;
      }
      if (_kForbiddenBaseline.contains(_key('X1', edge))) {
        continue;
      }
      offenders.add(_format(edge, '禁止边 ${edge.source} ↛ ${edge.target}'));
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason: '显式禁止边表命中（ADR-0036）：\n${offenders.join('\n')}',
    );
  });

  test('public 跨模块依赖图无环（import + export）', () {
    final Map<String, Set<String>> adjacency = <String, Set<String>>{};
    for (final _Edge edge in edges) {
      if (edge.deep) {
        continue;
      }
      if (!isProductModule(edge.source) || !isProductModule(edge.target)) {
        continue;
      }
      adjacency.putIfAbsent(edge.source, () => <String>{}).add(edge.target);
    }
    final List<String>? cycle = findPublicCrossFeatureCycle(adjacency);
    expect(
      cycle,
      isNull,
      reason: cycle == null ? null : 'public 依赖图存在环：${cycle.join(' → ')}',
    );
  });

  test('R13 baseline 无 stale 条目', () {
    final Set<String> produced = <String>{
      for (final _Edge edge in edges)
        if (edge.source == 'shared' && isProductModule(edge.target))
          _key('R13', edge),
    };
    final List<String> stale = <String>[
      ...baseline.where((String k) => k.startsWith('R13|')),
      ..._architectureBaseline.where((String k) => k.startsWith('R13|')),
    ].where((String k) => !produced.contains(k)).toList()..sort();
    expect(
      stale,
      isEmpty,
      reason: 'R13 baseline 存在失效条目（当前扫描已产不出该边，请删除）：\n${stale.join('\n')}',
    );
  });

  test('R12：public 面 export 自己的 presentation 必须显式登记且只减不增', () {
    final Set<String> allowlist = _loadR12Allowlist();
    expect(
      allowlist.length,
      lessThanOrEqualTo(_kR12AllowlistRatchet),
      reason: 'R12 白名单只能缩小（当前上限 $_kR12AllowlistRatchet）。',
    );

    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(libDir)) {
      if (isGeneratedDartFile(file.path)) {
        continue;
      }
      final String rel = libRelativePosixPath(libDir, file);
      if (!isFeaturePublicLayerPath(rel)) {
        continue;
      }
      final String sourceModule = classifyLibPath(rel);
      if (!isProductModule(sourceModule)) {
        continue;
      }
      final String contents = file.readAsStringSync();
      final RegExp ownPresentation = RegExp(
        "^(?:import|export)\\s+'package:hentai_library/features/$sourceModule/presentation/",
        multiLine: true,
      );
      if (ownPresentation.hasMatch(contents) && !allowlist.contains(rel)) {
        offenders.add(rel);
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'public 面引用自身 presentation 必须登记在 '
          'test/gate/public_presentation_export_allowlist.txt：\n'
          '${offenders.join('\n')}',
    );

    final List<String> stale = <String>[
      for (final String entry in allowlist)
        if (!_stillForwardingOwnPresentation(libDir, entry)) entry,
    ]..sort();
    expect(
      stale,
      isEmpty,
      reason: 'R12 白名单存在失效条目（文件已删或不含自身 presentation 引用）：\n${stale.join('\n')}',
    );
  });
}

List<_Edge> _collectEdges(Directory libDir) {
  final List<_Edge> edges = <_Edge>[];
  for (final File file in dartFilesUnder(libDir)) {
    if (isGeneratedDartFile(file.path)) {
      continue;
    }
    final String rel = libRelativePosixPath(libDir, file);
    if (!isCanonicalLibRelativePath(rel) &&
        isStranglerExportOnlyShim(file.readAsStringSync())) {
      continue;
    }
    final String source = classifyLibPath(rel);
    final String contents = file.readAsStringSync();
    for (final RegExpMatch match in _edgeUriRe.allMatches(contents)) {
      final String uriPath = match.group(1)!;
      final String? target = resolveImportTargetModule(uriPath, libDir);
      if (target == null || target == source) {
        continue;
      }
      final bool crossPresentation =
          isPresentationLayerPath(rel) &&
          uriPath.startsWith('features/') &&
          uriPath.contains('/presentation/');
      edges.add((
        source: source,
        target: target,
        file: rel,
        uri: 'package:hentai_library/$uriPath',
        deep: !isFeaturePublicPath(uriPath) && isProductModule(target),
        crossPresentation: crossPresentation,
      ));
    }
  }
  return edges;
}

String _key(String ruleId, _Edge edge) =>
    '$ruleId|${edge.source}|${edge.target}|${edge.file}|${edge.uri}';

String _format(_Edge edge, String message) =>
    '${edge.file} → ${edge.target} ($message) :: ${edge.uri}';

Set<String> _architectureBaseline = <String>{};

Set<String> _loadJson(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    return <String>{};
  }
  return (jsonDecode(file.readAsStringSync()) as List<dynamic>)
      .cast<String>()
      .toSet();
}

Set<String> _loadBaseline() {
  final File file = File(
    p.join(
      Directory.current.path,
      'test',
      'gate',
      'import_boundary_baseline.json',
    ),
  );
  final List<dynamic> raw =
      jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return raw.cast<String>().toSet();
}

Set<String> _loadR12Allowlist() {
  final File file = File(
    p.join(
      Directory.current.path,
      'test',
      'gate',
      'public_presentation_export_allowlist.txt',
    ),
  );
  return <String>{
    for (final String raw in file.readAsLinesSync())
      if (raw.trim().isNotEmpty && !raw.trim().startsWith('#')) raw.trim(),
  };
}

bool _stillForwardingOwnPresentation(Directory libDir, String rel) {
  final File file = File(p.join(libDir.path, p.joinAll(rel.split('/'))));
  if (!file.existsSync()) {
    return false;
  }
  final String module = classifyLibPath(rel);
  final RegExp ownPresentation = RegExp(
    "^(?:import|export)\\s+'package:hentai_library/features/$module/presentation/",
    multiLine: true,
  );
  return ownPresentation.hasMatch(file.readAsStringSync());
}
