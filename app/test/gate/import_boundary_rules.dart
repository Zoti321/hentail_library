import 'dart:io';

import 'package:path/path.dart' as p;

import 'wayfinder_layout_helpers.dart';

/// Module ids for Wayfinder import-boundary Gate (#220).
///
/// Keep in sync with `scripts/research/cross_feature_import_audit.py` (`classify`).
const Set<String> kImportBoundaryModules = <String>{
  'bootstrap',
  'home',
  'library_admin',
  'library_browse',
  'read_session',
  'comic_trash',
  'named_metadata',
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
  if (path.startsWith('shared/')) {
    return 'shared';
  }
  if (path.startsWith('src/rust/')) {
    return 'frb_generated';
  }
  if (path == 'main.dart') {
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

bool isFrbImportAllowedSource(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  if (path == 'main.dart') {
    return true;
  }
  if (path.startsWith('shared/data/')) {
    return true;
  }
  // Wayfinder Phase C (#256 / #280): FRB thin edge lives in owner feature data/.
  if (path.startsWith('features/') && path.contains('/data/')) {
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
  }
  return found;
}

void _checkStructuralRules({
  required List<ImportViolation> found,
  required String sourceRel,
  required String sourceModule,
  required String importPath,
  required String importUri,
  required String targetModule,
}) {
  if (isDomainLayerPath(sourceRel)) {
    final bool domainImportsSharedData = importPath.startsWith('shared/data/');
    final bool domainImportsOwnFeatureData =
        isProductModule(sourceModule) &&
        importPath.startsWith('features/$sourceModule/data/');
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

  if (sourceModule == 'library_browse') {
    if (importPath.startsWith('features/read_session/')) {
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

  found.add(
    violation(
      ruleId: 'M1',
      sourceModule: sourceModule,
      targetModule: targetModule,
      sourceFile: sourceRel,
      importUri: importUri,
    ),
  );

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

List<ImportViolation> structuralViolations(List<ImportViolation> all) {
  return all.where((ImportViolation v) => v.ruleId.startsWith('R')).toList();
}

List<ImportViolation> ratchetViolations(List<ImportViolation> all) {
  return all
      .where(
        (ImportViolation v) =>
            v.ruleId == 'M1' || v.ruleId == 'M2' || v.ruleId == 'M3',
      )
      .toList();
}

Set<String> violationKeySet(List<ImportViolation> violations) {
  return violations.map(violationKey).toSet();
}
