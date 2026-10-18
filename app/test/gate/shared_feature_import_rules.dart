import 'dart:io';

import 'package:path/path.dart' as p;

/// `shared/data` paths that may import `features/` outside the adapters tree.
///
/// Phase C (#256): FRB thin edges; keep in sync with
/// [docs/agents/testing.md] and `import_boundary_rules.dart` FRB allowlist.
const Set<String> kSharedDataExplicitFeatureImportAllowlist = <String>{
  'shared/data/adapters/reader_frb_mapper.dart',
  'shared/data/adapters/series_frb_mapper.dart',
};

final RegExp _featureImportLineRe = RegExp(
  r"^import\s+'package:hentai_library/features/([^']+)';",
);

bool importsFeaturePackageLine(String line) {
  return _featureImportLineRe.hasMatch(line.trim());
}

String? parseFeatureImportUri(String line) {
  final Match? match = _featureImportLineRe.matchAsPrefix(line.trim());
  if (match == null) {
    return null;
  }
  return 'package:hentai_library/features/${match.group(1)}';
}

/// Whole `shared/data/adapters/**` may import features (FRB mappers); see issue #295.
bool isSharedDataFeatureImportExempt(String libRelativePosix) {
  final String path = libRelativePosix.replaceAll(r'\', '/');
  if (path.startsWith('shared/data/adapters/')) {
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
