import 'dart:io';

import 'package:path/path.dart' as p;

import 'lib_layout_scan_helpers.dart';

/// Feature / module ids for import-boundary Gate (#220).
///
/// Keep in sync with `scripts/research/cross_feature_import_audit.py` (`classify`).
const Set<String> kImportBoundaryModules = <String>{
  'bootstrap',
  'home',
  'library_admin',
  'library_browse',
  'comic',
  'series',
  'reader',
  'reading_history',
  'reading_stats',
  'comic_trash',
  'comic_metadata',
  'app_settings',
  'metadata_backup',
  'shared',
  'frb_generated',
};

const String _packagePrefix = 'package:hentai_library/';

final RegExp _importUriRe = RegExp(
  r"^import\s+'package:hentai_library/([^']+)';",
  multiLine: true,
);

/// `export` of own `presentation/` from `public/` (R12); M1/M2/M3 stay import-only.
final RegExp _exportUriRe = RegExp(
  r"^export\s+'package:hentai_library/([^']+)';",
  multiLine: true,
);

/// lib-relative paths allowed to `export` own feature `presentation/` (R12).
/// Source: `app/test/gate/public_presentation_export_allowlist.txt` (only shrink).
Set<String>? _publicPresentationExportAllowlistCache;

Set<String> publicPresentationExportAllowlist({Directory? gateDir}) {
  final Set<String>? cached = _publicPresentationExportAllowlistCache;
  if (cached != null && gateDir == null) {
    return cached;
  }
  final Directory dir =
      gateDir ?? Directory(p.join(Directory.current.path, 'test', 'gate'));
  final File file = File(
    p.join(dir.path, 'public_presentation_export_allowlist.txt'),
  );
  final Set<String> entries = <String>{};
  if (file.existsSync()) {
    for (final String raw in file.readAsLinesSync()) {
      final String line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }
      entries.add(line.replaceAll(r'\', '/'));
    }
  }
  if (gateDir == null) {
    _publicPresentationExportAllowlistCache = entries;
  }
  return entries;
}

bool isPublicPresentationExportAllowlisted(String libRelativePosix) {
  return publicPresentationExportAllowlist().contains(
    libRelativePosix.replaceAll(r'\', '/'),
  );
}

bool isPublicPresentationFacadeExport(
  String source,
  String target, [
  String contents = '',
]) {
  final String module = classifyLibPath(source);
  if (source.startsWith('features/$module/public/providers/') &&
      target.startsWith('features/$module/presentation/providers/')) {
    return true;
  }
  if ((source == 'features/$module/public/providers.dart' ||
          source == 'features/$module/public/widgets.dart') &&
      target.startsWith('features/$module/presentation/')) {
    return true;
  }
  if (!source.startsWith('features/$module/public/') ||
      !target.startsWith('features/$module/presentation/')) {
    return false;
  }
  return RegExp(
    "^export\\s+'package:hentai_library/${RegExp.escape(target)}'\\s+show\\s+[A-Za-z0-9_,\\s]+;",
    multiLine: true,
  ).hasMatch(contents);
}

final RegExp _exportOnlyShimRe = RegExp(
  r"^\s*export\s+'package:hentai_library/[^']+';\s*$",
);

bool isGeneratedDartFile(String posixPath) {
  final String name = p.basename(posixPath);
  return name.endsWith('.g.dart') ||
      name.endsWith('.freezed.dart') ||
      name.startsWith('frb_generated');
}

bool isStranglerExportOnlyShim(String fileContents) {
  final String trimmed = fileContents.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final List<String> lines = trimmed
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && !line.startsWith('//'))
      .toList();
  if (lines.length != 1) {
    return false;
  }
  return _exportOnlyShimRe.hasMatch(lines.single);
}

bool isProductModule(String moduleId) {
  return moduleId != 'shared' &&
      moduleId != 'bootstrap' &&
      moduleId != 'frb_generated';
}

/// Classify a lib-relative POSIX path to a module id.
String classifyLibPath(String relativePosix) {
  final String path = relativePosix.replaceAll(r'\', '/');

  if (path.startsWith('features/')) {
    final List<String> parts = path.split('/');
    if (parts.length >= 2) {
      return parts[1];
    }
  }
  if (path.startsWith('shared/') || path.startsWith('design-system/')) {
    return 'shared';
  }
  if (path.startsWith('src/rust/')) {
    return 'frb_generated';
  }
  if (path.startsWith('composition/') || path == 'main.dart') {
    return 'bootstrap';
  }
  return 'shared';
}

String? resolveImportTargetModule(String importPath, Directory libDir) {
  if (importPath.startsWith('src/rust/')) {
    return 'frb_generated';
  }
  final File? target = _resolveLibFile(importPath, libDir);
  if (target == null) {
    return null;
  }
  final String rel = p.posix.normalize(
    p.relative(target.path, from: libDir.path).replaceAll(r'\', '/'),
  );
  return classifyLibPath(rel);
}

File? _resolveLibFile(String importPath, Directory libDir) {
  final File direct = File(p.join(libDir.path, importPath));
  if (direct.existsSync()) {
    return direct;
  }
  final File asDart = File('${p.join(libDir.path, importPath)}.dart');
  if (asDart.existsSync()) {
    return asDart;
  }
  return null;
}

bool isPresentationLayerPath(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  if (path.startsWith('features/') && path.contains('/presentation/')) {
    return true;
  }
  return path.startsWith('shared/ui/');
}

bool isDomainLayerPath(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  if (path.startsWith('features/') && path.contains('/domain/')) {
    return true;
  }
  return path.contains('/domain/');
}

bool isApplicationLayerPath(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  return path.contains('/application/');
}

/// Cross-feature allowlist (#427 / ADR-0034): `features/<owner>/public/**` only.
bool isFeaturePublicPath(String importPath) {
  final String path = importPath.replaceAll(r'\', '/');
  if (!path.startsWith('features/')) {
    return false;
  }
  final List<String> parts = path.split('/');
  if (parts.length < 3) {
    return false;
  }
  if (parts[2] == 'public') {
    return true;
  }
  return parts.length == 3 && parts[2] == 'public.dart';
}

bool isFeaturePublicLayerPath(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  return path.startsWith('features/') && path.contains('/public/');
}

bool _importTargetsFeatureApplication(String importPath) {
  return importPath.contains('/application/');
}

bool _importTargetsDataLayer(String importPath) {
  if (importPath.startsWith('infrastructure/')) {
    return true;
  }
  return importPath.startsWith('features/') &&
      importPath.contains('/infrastructure/');
}

bool _importTargetsPresentationLayer(String importPath) {
  if (isPresentationLayerPath(importPath)) {
    return true;
  }
  return importPath.startsWith('features/') &&
      importPath.contains('/presentation/');
}

bool isFrbImportAllowedSource(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  if (path == 'main.dart') {
    return true;
  }
  if (path.startsWith('infrastructure/')) {
    return true;
  }
  // FRB calls stay in owner infrastructure; composition only selects adapters.
  if (path.startsWith('features/') && path.contains('/infrastructure/')) {
    return true;
  }
  return false;
}

/// Normalized violation signature for L1/L2.
typedef ImportViolation = ({
  String ruleId,
  String sourceModule,
  String targetModule,
  String sourceFile,
  String importUri,
});

String violationKey(ImportViolation v) {
  return '${v.ruleId}|${v.sourceModule}|${v.targetModule}|${v.sourceFile}|${v.importUri}';
}

ImportViolation violation({
  required String ruleId,
  required String sourceModule,
  required String targetModule,
  required String sourceFile,
  required String importUri,
}) {
  return (
    ruleId: ruleId,
    sourceModule: sourceModule,
    targetModule: targetModule,
    sourceFile: sourceFile,
    importUri: importUri,
  );
}

List<ImportViolation> collectImportViolations(Directory libDir) {
  final List<ImportViolation> found = <ImportViolation>[];
  final Iterable<File> dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'));

  for (final File file in dartFiles) {
    final String rel = p.posix.normalize(
      p.relative(file.path, from: libDir.path).replaceAll(r'\', '/'),
    );
    if (isGeneratedDartFile(rel)) {
      continue;
    }
    final String contents = file.readAsStringSync();
    if (!isCanonicalLibRelativePath(rel) &&
        isStranglerExportOnlyShim(contents)) {
      continue;
    }
    final String sourceModule = classifyLibPath(rel);
    for (final RegExpMatch match in _importUriRe.allMatches(contents)) {
      final String importPath = match.group(1)!;
      final String importUri = '$_packagePrefix$importPath';
      final String? targetModule = resolveImportTargetModule(
        importPath,
        libDir,
      );
      if (targetModule == null) {
        continue;
      }
      _checkStructuralRules(
        sourceContents: contents,
        found: found,
        sourceRel: rel,
        sourceModule: sourceModule,
        importPath: importPath,
        importUri: importUri,
        targetModule: targetModule,
      );
      _checkModuleGraphRules(
        found: found,
        sourceRel: rel,
        sourceModule: sourceModule,
        importPath: importPath,
        importUri: importUri,
        targetModule: targetModule,
      );
    }
    // R12 also covers `export` of own presentation from public/ (ADR-0034).
    // Cross-feature deep `export` (e.g. browse bridges) stay import-only for M1.
    if (isFeaturePublicLayerPath(rel) && isProductModule(sourceModule)) {
      for (final RegExpMatch match in _exportUriRe.allMatches(contents)) {
        final String importPath = match.group(1)!;
        if (!importPath.startsWith('features/$sourceModule/presentation/')) {
          continue;
        }
        final String importUri = '$_packagePrefix$importPath';
        final String? targetModule = resolveImportTargetModule(
          importPath,
          libDir,
        );
        if (targetModule == null) {
          continue;
        }
        _checkStructuralRules(
          sourceContents: contents,
          found: found,
          sourceRel: rel,
          sourceModule: sourceModule,
          importPath: importPath,
          importUri: importUri,
          targetModule: targetModule,
        );
      }
    }
  }
  return found;
}

void _checkStructuralRules({
  required String sourceContents,
  required List<ImportViolation> found,
  required String sourceRel,
  required String sourceModule,
  required String importPath,
  required String importUri,
  required String targetModule,
}) {
  if (isDomainLayerPath(sourceRel)) {
    final bool domainImportsSharedData = importPath.startsWith(
      'infrastructure/',
    );
    final bool domainImportsOwnFeatureData =
        isProductModule(sourceModule) &&
        importPath.startsWith('features/$sourceModule/infrastructure/');
    if (domainImportsSharedData || domainImportsOwnFeatureData) {
      found.add(
        violation(
          ruleId: 'R1',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
    }
    if (_importTargetsFeatureApplication(importPath)) {
      found.add(
        violation(
          ruleId: 'R6',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
    }
  }

  if (isApplicationLayerPath(sourceRel)) {
    if (_importTargetsDataLayer(importPath)) {
      found.add(
        violation(
          ruleId: 'R7',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
    }
    if (_importTargetsPresentationLayer(importPath)) {
      found.add(
        violation(
          ruleId: 'R8',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
    }
    if (importPath.startsWith('flutter/') ||
        importPath.startsWith('flutter_')) {
      found.add(
        violation(
          ruleId: 'R9',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
    }
  }

  if (targetModule == 'frb_generated' && !isFrbImportAllowedSource(sourceRel)) {
    if (sourceRel.startsWith('features/') && sourceRel.contains('/domain/')) {
      found.add(
        violation(
          ruleId: 'R3',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
      return;
    }
    if (isApplicationLayerPath(sourceRel)) {
      found.add(
        violation(
          ruleId: 'R10',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
      return;
    }
    if (sourceRel.startsWith('features/') &&
        sourceRel.contains('/presentation/')) {
      found.add(
        violation(
          ruleId: 'R4',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
      return;
    }
    found.add(
      violation(
        ruleId: 'R2',
        sourceModule: sourceModule,
        targetModule: targetModule,
        sourceFile: sourceRel,
        importUri: importUri,
      ),
    );
  }

  if (sourceModule == 'library_browse' ||
      sourceModule == 'comic' ||
      sourceModule == 'series') {
    if (importPath.startsWith('features/reader/')) {
      found.add(
        violation(
          ruleId: 'R5',
          sourceModule: sourceModule,
          targetModule: targetModule,
          sourceFile: sourceRel,
          importUri: importUri,
        ),
      );
    }
  }

  if (sourceModule == 'shared' &&
      importPath.startsWith('features/') &&
      isFeaturePublicPath(importPath)) {
    found.add(
      violation(
        ruleId: 'R11',
        sourceModule: sourceModule,
        targetModule: targetModule,
        sourceFile: sourceRel,
        importUri: importUri,
      ),
    );
  }

  // R13（`shared/**` 不得 import/export `features/**`）只由
  // `test/architecture/module_boundary_test.dart` 实现（扫 import + export），
  // 本文件不再产出该规则（#504）。

  if (isFeaturePublicLayerPath(sourceRel) &&
      isProductModule(sourceModule) &&
      importPath.startsWith('features/$sourceModule/presentation/') &&
      !isPublicPresentationFacadeExport(
        sourceRel,
        importPath,
        sourceContents,
      ) &&
      !isPublicPresentationExportAllowlisted(sourceRel)) {
    found.add(
      violation(
        ruleId: 'R12',
        sourceModule: sourceModule,
        targetModule: targetModule,
        sourceFile: sourceRel,
        importUri: importUri,
      ),
    );
  }
}

void _checkModuleGraphRules({
  required List<ImportViolation> found,
  required String sourceRel,
  required String sourceModule,
  required String importPath,
  required String importUri,
  required String targetModule,
}) {
  if (!kImportBoundaryModules.contains(sourceModule) ||
      !kImportBoundaryModules.contains(targetModule)) {
    return;
  }
  if (sourceModule == targetModule) {
    return;
  }
  if (sourceModule == 'shared' || targetModule == 'shared') {
    return;
  }
  if (sourceModule == 'bootstrap') {
    return;
  }
  // R6 (ratchet M3): product feature must not depend on the bootstrap composition
  // root (#260). Existing edges live in the baseline and must only shrink.
  if (isProductModule(sourceModule) && targetModule == 'bootstrap') {
    found.add(
      violation(
        ruleId: 'M3',
        sourceModule: sourceModule,
        targetModule: targetModule,
        sourceFile: sourceRel,
        importUri: importUri,
      ),
    );
    return;
  }
  if (!isProductModule(sourceModule) || !isProductModule(targetModule)) {
    return;
  }

  if (!isFeaturePublicPath(importPath)) {
    found.add(
      violation(
        ruleId: 'M1',
        sourceModule: sourceModule,
        targetModule: targetModule,
        sourceFile: sourceRel,
        importUri: importUri,
      ),
    );
  }

  final bool targetIsPresentation =
      isPresentationLayerPath(importPath) ||
      (importPath.startsWith('features/') &&
          importPath.contains('/presentation/'));
  if (isPresentationLayerPath(sourceRel) && targetIsPresentation) {
    found.add(
      violation(
        ruleId: 'M2',
        sourceModule: sourceModule,
        targetModule: targetModule,
        sourceFile: sourceRel,
        importUri: importUri,
      ),
    );
  }
}

/// Rules enforced with a shrink-only baseline instead of zero tolerance.
const Set<String> kRatchetRuleIds = <String>{'M1', 'M2', 'M3'};

List<ImportViolation> structuralViolations(List<ImportViolation> all) {
  return all
      .where(
        (ImportViolation v) =>
            v.ruleId.startsWith('R') && !kRatchetRuleIds.contains(v.ruleId),
      )
      .toList();
}

List<ImportViolation> ratchetViolations(List<ImportViolation> all) {
  return all
      .where((ImportViolation v) => kRatchetRuleIds.contains(v.ruleId))
      .toList();
}

Set<String> violationKeySet(List<ImportViolation> violations) {
  return violations.map(violationKey).toSet();
}

/// Directed edges `sourceModule -> targetModule` for public-only cross-feature imports.
Map<String, Set<String>> collectPublicCrossFeatureAdjacency(Directory libDir) {
  final Map<String, Set<String>> adjacency = <String, Set<String>>{};
  final Iterable<File> dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'));

  for (final File file in dartFiles) {
    final String rel = p.posix.normalize(
      p.relative(file.path, from: libDir.path).replaceAll(r'\', '/'),
    );
    if (isGeneratedDartFile(rel)) {
      continue;
    }
    final String contents = file.readAsStringSync();
    if (!isCanonicalLibRelativePath(rel) &&
        isStranglerExportOnlyShim(contents)) {
      continue;
    }
    final String sourceModule = classifyLibPath(rel);
    if (!isProductModule(sourceModule)) {
      continue;
    }
    for (final RegExpMatch match in _importUriRe.allMatches(contents)) {
      final String importPath = match.group(1)!;
      if (!isFeaturePublicPath(importPath)) {
        continue;
      }
      final String? targetModule = resolveImportTargetModule(
        importPath,
        libDir,
      );
      if (targetModule == null ||
          !isProductModule(targetModule) ||
          sourceModule == targetModule) {
        continue;
      }
      adjacency.putIfAbsent(sourceModule, () => <String>{}).add(targetModule);
    }
  }
  return adjacency;
}

/// Returns one cycle as module ids, or null if acyclic.
List<String>? findPublicCrossFeatureCycle(Map<String, Set<String>> adjacency) {
  final Set<String> allNodes = <String>{
    ...adjacency.keys,
    for (final Set<String> targets in adjacency.values) ...targets,
  };
  final Set<String> visited = <String>{};
  final Set<String> inStack = <String>{};
  List<String>? cycle;

  void dfs(String node, List<String> path) {
    if (cycle != null) {
      return;
    }
    if (inStack.contains(node)) {
      final int start = path.indexOf(node);
      cycle = <String>[...path.sublist(start), node];
      return;
    }
    if (visited.contains(node)) {
      return;
    }
    visited.add(node);
    inStack.add(node);
    path.add(node);
    for (final String next in adjacency[node] ?? const <String>{}) {
      dfs(next, path);
    }
    path.removeLast();
    inStack.remove(node);
  }

  for (final String node in allNodes) {
    dfs(node, <String>[]);
    if (cycle != null) {
      break;
    }
  }
  return cycle;
}
