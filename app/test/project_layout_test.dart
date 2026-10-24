import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'gate/wayfinder_layout_helpers.dart';

void main() {
  group('monorepo layout', () {
    late Directory repoRoot;

    setUp(() {
      // app/test → repo root
      repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..')));
    });

    test('Flutter app lives under app/', () {
      expect(
        Directory(p.join(repoRoot.path, 'app', 'lib')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(repoRoot.path, 'app', 'pubspec.yaml')).existsSync(),
        isTrue,
      );
      expect(Directory(p.join(repoRoot.path, 'lib')).existsSync(), isFalse);
      expect(File(p.join(repoRoot.path, 'pubspec.yaml')).existsSync(), isFalse);
    });

    test('repo root keeps collaboration docs', () {
      expect(File(p.join(repoRoot.path, 'GLOSSARY.md')).existsSync(), isTrue);
      expect(Directory(p.join(repoRoot.path, 'docs')).existsSync(), isTrue);
      expect(Directory(p.join(repoRoot.path, '.github')).existsSync(), isTrue);
    });

    test('design-system MASTER declares directory charter (ADR-0029)', () {
      final File master = File(
        p.join(repoRoot.path, 'design-system', 'hentai-library', 'MASTER.md'),
      );
      expect(master.existsSync(), isTrue);
      final String content = master.readAsStringSync();
      expect(content, contains('## Directory charter'));
      expect(content, contains('pages/[page-name].md'));
      expect(
        Directory(
          p.join(repoRoot.path, 'design-system', 'hentai-library', 'pages'),
        ).existsSync(),
        isTrue,
      );
    });

    test('core/ Rust workspace exists', () {
      expect(Directory(p.join(repoRoot.path, 'core')).existsSync(), isTrue);
      expect(
        File(p.join(repoRoot.path, 'core', 'Cargo.toml')).existsSync(),
        isTrue,
      );
    });
  });

  group('app/lib top-level layout (#219 Wayfinder)', () {
    late Directory libDir;

    setUp(() {
      libDir = Directory(p.join(Directory.current.path, 'lib'));
    });

    test('Phase A: only allowed top-level directories exist', () {
      final Set<String> actualNames = libDir
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => p.basename(d.path))
          .toSet();
      final List<String> unexpected = actualNames
          .where(
            (String name) => !kWayfinderPhaseATopLevelLibDirs.contains(name),
          )
          .toList();
      expect(
        unexpected,
        isEmpty,
        reason: 'Unexpected top-level lib dirs: $unexpected',
      );
    });

    test(
      'Phase B: end-state top-level directories (enabled at bootstrap-final)',
      () {
        if (!kEnforceWayfinderPhaseBLayout) {
          return;
        }
        final Set<String> actualNames = libDir
            .listSync()
            .whereType<Directory>()
            .map((Directory d) => p.basename(d.path))
            .toSet();
        expect(actualNames, kWayfinderPhaseBTopLevelLibDirs);
      },
      skip: kEnforceWayfinderPhaseBLayout ? false : 'bootstrap-final slice',
    );

    test('features/ modules use canonical ids and layer folders only', () {
      final Directory featuresDir = Directory(p.join(libDir.path, 'features'));
      if (!featuresDir.existsSync()) {
        return;
      }
      final List<String> badModuleIds = <String>[];
      final List<String> badLayerDirs = <String>[];
      for (final FileSystemEntity entity in featuresDir.listSync()) {
        if (entity is! Directory) {
          continue;
        }
        final String moduleId = p.basename(entity.path);
        if (!kWayfinderFeatureModuleIds.contains(moduleId)) {
          badModuleIds.add(moduleId);
        }
        for (final FileSystemEntity child in entity.listSync()) {
          if (child is! Directory) {
            continue;
          }
          final String layer = p.basename(child.path);
          if (!kWayfinderFeatureLayerDirs.contains(layer)) {
            badLayerDirs.add(p.posix.join('features', moduleId, layer));
          }
        }
      }
      expect(badModuleIds, isEmpty);
      expect(badLayerDirs, isEmpty);
    });

    test('no presentation/state/ directories under lib/', () {
      expect(findPresentationStateDirs(libDir), isEmpty);
    });
  });

  group('UI presentation layout (ADR-0017)', () {
    test('features keep ViewModels under view_models/, not state/', () {
      final List<String> stateDirs = <String>['lib', 'test']
          .map((String root) => Directory(p.join(root, 'features')))
          .where((Directory dir) => dir.existsSync())
          .expand((Directory dir) => dir.listSync(recursive: true))
          .whereType<Directory>()
          .where((Directory dir) => p.basename(dir.path) == 'state')
          .map((Directory dir) => p.posix.joinAll(p.split(dir.path)))
          .toList();
      expect(stateDirs, isEmpty);
    });

    test('views and shared/ui widgets never touch Repository providers', () {
      final RegExp repoProvider = RegExp(r'\b\w+RepoProvider\b');
      final Directory libRoot = Directory('lib');
      if (!libRoot.existsSync()) {
        return;
      }
      final List<String> offenders = libRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .where((File file) {
            final String rel = p.posix.joinAll(
              p.split(p.relative(file.path, from: libRoot.path)),
            );
            final bool isView =
                rel.startsWith('features/') && rel.split('/').contains('views');
            final bool isSharedUi = rel.startsWith('shared/ui/');
            return isView || isSharedUi;
          })
          .where((File file) => repoProvider.hasMatch(file.readAsStringSync()))
          .map((File file) => p.posix.joinAll(p.split(file.path)))
          .toList();
      expect(offenders, isEmpty);
    });
  });
}
