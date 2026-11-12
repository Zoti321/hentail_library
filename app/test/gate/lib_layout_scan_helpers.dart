import 'dart:io';

import 'package:path/path.dart' as p;

/// Phase B (end-state): enabled at bootstrap-final (#258 / #219).
const bool kEnforceWayfinderPhaseBLayout = true;

/// Phase A allow-list; legacy `data/` `domain/` `ui/` roots were removed in #258.
/// `core/` is the app cross-cutting kernel (l10n, logging, util), moved back to
/// `lib/core` on 2026-10-18 (layout rules: `docs/engineering/gate.md` § App lib 顶层布局).
/// `md3e/` was removed at MD3E Cutover shell终态 (#414 / ADR-0031).
const Set<String> kWayfinderPhaseATopLevelLibDirs = <String>{
  'composition',
  'infrastructure',
  'core',
  'design-system',
  'features',
  'shared',
  'src',
};

const Set<String> kWayfinderPhaseBTopLevelLibDirs = <String>{
  'composition',
  'infrastructure',
  'core',
  'design-system',
  'features',
  'shared',
  'src',
};

/// Canonical lib-relative roots. Only files *outside* these roots can be
/// legacy strangler shims; barrels inside `features/` or `shared/` are normal.
bool isCanonicalLibRelativePath(String rel) {
  final String path = rel.replaceAll(r'\', '/');
  return path.startsWith('composition/') ||
      path.startsWith('infrastructure/') ||
      path.startsWith('features/') ||
      path.startsWith('shared/') ||
      path.startsWith('src/') ||
      path.startsWith('design-system/');
}

List<String> readStranglerShimAllowlist(File manifest) {
  return manifest
      .readAsLinesSync()
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && !line.startsWith('#'))
      .map((String line) => p.posix.normalize(line))
      .toList();
}

String libRelativePosixPath(Directory libDir, File dartFile) {
  final String relative = p.relative(dartFile.path, from: libDir.path);
  return p.posix.joinAll(p.split(relative));
}

final RegExp _packageExport = RegExp(
  r"^export\s+'package:hentai_library/([^']+)'\s*;\s*$",
);

/// Strangler shims re-export only `features/` or `shared/` canonical URIs (#219).
/// Legacy barrels (relative or package `ui/` / `domain/` re-exports) are not shims.
bool isStranglerShimSource(String source) {
  final List<String> lines = source.split('\n');
  var sawExport = false;
  for (final String raw in lines) {
    final String line = raw.trim();
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('//')) {
      continue;
    }
    if (line.startsWith('/*') || line.startsWith('*') || line == '*/') {
      continue;
    }
    final Match? match = _packageExport.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final String uriPath = match.group(1)!;
    if (!uriPath.startsWith('features/') && !uriPath.startsWith('shared/')) {
      return false;
    }
    sawExport = true;
  }
  return sawExport;
}

Iterable<File> dartFilesUnder(Directory root) sync* {
  if (!root.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

List<String> findPresentationStateDirs(Directory libDir) {
  final List<String> offenders = <String>[];
  if (!libDir.existsSync()) {
    return offenders;
  }
  for (final FileSystemEntity entity in libDir.listSync(recursive: true)) {
    if (entity is! Directory) {
      continue;
    }
    if (p.basename(entity.path) != 'state') {
      continue;
    }
    final Directory parent = entity.parent;
    if (p.basename(parent.path) != 'presentation') {
      continue;
    }
    offenders.add(libRelativePosixPath(libDir, File(entity.path)));
  }
  offenders.sort();
  return offenders;
}

List<String> collectStranglerShims(Directory libDir) {
  final List<String> shims = <String>[];
  for (final File file in dartFilesUnder(libDir)) {
    final String rel = libRelativePosixPath(libDir, file);
    if (isCanonicalLibRelativePath(rel)) {
      continue;
    }
    final String source = file.readAsStringSync();
    if (isStranglerShimSource(source)) {
      shims.add(rel);
    }
  }
  shims.sort();
  return shims;
}

final RegExp _anyPackageExport = RegExp(
  r"^export\s+'package:hentai_library/([^']+)'\s*;\s*$",
);

/// `shared/**` 下「只做转发」到 `features/**` 的文件（ADR-0045 / #504）。
///
/// canonical 路径不受 [collectStranglerShims] 覆盖，`shared/` 曾因此可以长期
/// 保留 export-only 转发（例如 `shared/presentation/providers/home_library_stats_providers.dart`）。
/// 允许前置注释与 `library;` 指令，但除 package export 外不得有任何代码。
List<String> collectSharedFeatureForwarders(Directory libDir) {
  final Directory root = Directory(p.join(libDir.path, 'shared'));
  if (!root.existsSync()) {
    return <String>[];
  }
  final List<String> forwarders = <String>[];
  for (final File file in dartFilesUnder(root)) {
    final String rel = libRelativePosixPath(libDir, file);
    final String name = p.basename(rel);
    if (name.endsWith('.g.dart') ||
        name.endsWith('.freezed.dart') ||
        name.startsWith('frb_generated')) {
      continue;
    }
    if (isSharedFeatureForwarderSource(file.readAsStringSync())) {
      forwarders.add(rel);
    }
  }
  forwarders.sort();
  return forwarders;
}

/// 文件是否只由 package export 组成且至少有一条指向 `features/**`。
bool isSharedFeatureForwarderSource(String source) {
  var sawExport = false;
  var targetsFeature = false;
  for (final String raw in source.split('\n')) {
    final String line = raw.trim();
    if (line.isEmpty ||
        line.startsWith('//') ||
        line.startsWith('/*') ||
        line.startsWith('*') ||
        line == '*/' ||
        line == 'library;') {
      continue;
    }
    final Match? match = _anyPackageExport.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    sawExport = true;
    if (match.group(1)!.startsWith('features/')) {
      targetsFeature = true;
    }
  }
  return sawExport && targetsFeature;
}
