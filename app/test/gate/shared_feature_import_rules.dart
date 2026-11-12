import 'dart:io';

import 'package:path/path.dart' as p;

/// `shared/data` paths that may import `features/` outside the adapters tree.
///
/// Phase C (#256): FRB thin edges; keep in sync with
/// [docs/engineering/gate.md] and `import_boundary_rules.dart` FRB allowlist.
/// `shared/data` paths that may import `features/` outside the adapters tree.
///
/// Phase C (#256): FRB thin edges; keep in sync with
/// [docs/engineering/gate.md] and `import_boundary_rules.dart` FRB allowlist.
const Set<String> kSharedDataExplicitFeatureImportAllowlist = <String>{};

final RegExp _featureImportUriRe = RegExp(
  "package:hentai_library/features/([^'\"]+)",
);

bool importsFeaturePackageLine(String line) {
  final String trimmed = line.trim();
  return trimmed.startsWith('import ') &&
      trimmed.contains('package:hentai_library/features/');
}

String? parseFeatureImportUri(String line) {
  if (!importsFeaturePackageLine(line)) {
    return null;
  }
  final Match? match = _featureImportUriRe.firstMatch(line);
  if (match == null) {
    return null;
  }
  return 'package:hentai_library/features/${match.group(1)}';
}

/// `infrastructure/mappers/**` and `infrastructure/adapters/**` may import features (#295).
bool isSharedDataFeatureImportExempt(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  if (path.startsWith('infrastructure/adapters/') ||
      path.startsWith('infrastructure/mappers/')) {
    return true;
  }
  return kSharedDataExplicitFeatureImportAllowlist.contains(path);
}

String sharedDomainFeatureImportViolationKey({
  required String sourceFile,
  required String importUri,
}) {
  return '$sourceFile|$importUri';
}

/// Scans `shared/domain/**` for `import package:hentai_library/features/...` (not comments).
Set<String> collectSharedDomainFeatureImportViolationKeys(Directory libDir) {
  final Directory root = Directory(p.join(libDir.path, 'shared', 'domain'));
  if (!root.existsSync()) {
    return <String>{};
  }
  final Set<String> keys = <String>{};
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String rel = p
        .relative(entity.path, from: libDir.path)
        .replaceAll(r'\', '/');
    final List<String> lines = entity.readAsLinesSync();
    for (final String line in lines) {
      final String? importUri = parseFeatureImportUri(line);
      if (importUri == null) {
        continue;
      }
      keys.add(
        sharedDomainFeatureImportViolationKey(
          sourceFile: rel,
          importUri: importUri,
        ),
      );
    }
  }
  return keys;
}
