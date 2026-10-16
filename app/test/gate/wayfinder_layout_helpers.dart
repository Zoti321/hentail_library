import 'dart:io';

import 'package:path/path.dart' as p;

/// Phase B (post-bootstrap): enable in the final bootstrap slice (#219).
const bool kEnforceWayfinderPhaseBLayout = false;

const Set<String> kWayfinderPhaseATopLevelLibDirs = <String>{
  'core',
  'data',
  'domain',
  'features',
  'shared',
  'src',
  'ui',
};

const Set<String> kWayfinderPhaseBTopLevelLibDirs = <String>{
  'features',
  'shared',
  'src',
};

/// Feature module ids (#218 / #219).
const Set<String> kWayfinderFeatureModuleIds = <String>{
  'app_settings',
  'bootstrap',
  'comic_trash',
  'home',
  'library_admin',
  'library_browse',
  'metadata_backup',
  'named_metadata',
  'read_session',
};

const Set<String> kWayfinderFeatureLayerDirs = <String>{
  'data',
  'domain',
  'presentation',
};

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
    final String source = file.readAsStringSync();
    if (isStranglerShimSource(source)) {
      shims.add(libRelativePosixPath(libDir, file));
    }
  }
  shims.sort();
  return shims;
}
