import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// 依赖倒置门禁（ADR-0034 §3 / ADR-0039 / #488）。
///
/// - `presentation/**` 不 import 本模块 `data/**`（状态实现归 owner DI，视图不直连仓储）。
/// - `presentation/**` 不 import 领域事件实现（只经 ViewModel / Port 转发）。
/// - `shared/di` 声明的 token 必须在应用组合根有 override。
void main() {
  late Directory libDir;

  setUpAll(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test('presentation 不 import 本模块 data/', () {
    const Set<String> outOfScopeBaseline = <String>{
      'features/library_admin/presentation/views/library/library_form_dialog.dart',
      'features/metadata_backup/presentation/metadata_export_flow.dart',
      'features/metadata_backup/presentation/metadata_import_flow.dart',
      'features/metadata_backup/presentation/view_models/metadata_auto_backup_coordinator_notifier.dart',
      'features/metadata_backup/presentation/views/metadata_backup_settings_sections.dart',
    };
    final List<String> offenders = _presentationDataEdges(libDir)
        .where((String rel) => !outOfScopeBaseline.contains(rel))
        .toList();
    expect(
      offenders,
      isEmpty,
      reason: 'presentation 直连 data 破坏依赖倒置：\n${offenders.join('\n')}',
    );
  });

  test('presentation 不 import 领域事件实现', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(
      Directory(p.join(libDir.path, 'features')),
    )) {
      if (isGeneratedDartFile(file.path)) {
        continue;
      }
      final String rel = libRelativePosixPath(libDir, file);
      if (!isPresentationLayerPath(rel)) {
        continue;
      }
      final String contents = file.readAsStringSync();
      if (contents.contains('shared/data/events/') ||
          contents.contains('shared/domain/events/domain_event_bus.dart')) {
        offenders.add(rel);
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'presentation 只能经 ViewModel/Port 发命令，不得直连事件总线实现'
          '（ADR-0039）：\n${offenders.join('\n')}',
    );
  });

  test('shared/di 每个注入 token 至少有一处 overrideWith', () {
    final Directory sharedDiDir = Directory(
      p.join(libDir.path, 'shared', 'di'),
    );
    final Directory featuresDir = Directory(p.join(libDir.path, 'features'));
    final Set<String> declared = _collectDeclaredTokens(sharedDiDir);
    final Set<String> overridden = _collectOverriddenTokens(featuresDir);

    expect(declared, isNotEmpty, reason: 'shared/di 未采集到任何 token');
    expect(overridden, isNotEmpty, reason: 'features/ 未采集到任何 overrideWith');

    final List<String> missing = declared.difference(overridden).toList()
      ..sort();
    expect(
      missing,
      isEmpty,
      reason:
          '以下 shared/di token 没有 overrideWith/overrideWithValue：\n'
          '${missing.join('\n')}',
    );
  });
}

List<String> _presentationDataEdges(Directory libDir) {
  final List<String> offenders = <String>[];
  for (final File file in dartFilesUnder(libDir)) {
    if (isGeneratedDartFile(file.path)) {
      continue;
    }
    final String rel = libRelativePosixPath(libDir, file);
    final String sourceModule = classifyLibPath(rel);
    if (!isProductModule(sourceModule) ||
        !rel.startsWith('features/') ||
        !isPresentationLayerPath(rel)) {
      continue;
    }
    final RegExp ownData = RegExp(
      "^(?:import|export)\\s+'package:hentai_library/features/$sourceModule/data/",
      multiLine: true,
    );
    final String contents = file.readAsStringSync();
    if (ownData.hasMatch(contents)) {
      offenders.add(rel);
    }
  }
  offenders.sort();
  return offenders;
}

final RegExp _typeFirstDeclaration = RegExp(
  r'final\s+(?:Provider|FutureProvider|StreamProvider|ProviderFamily|FutureProviderFamily|StreamProviderFamily)(?:\.(?:autoDispose|family))*\s*<[^=]*?>\s*(\w+Provider)\s*=',
);

final RegExp _nameFirstDeclaration = RegExp(
  r'final\s+(\w+Provider)\s*=\s*(?:Provider|FutureProvider|StreamProvider)(?:\.(?:autoDispose|family))*\s*[<(]',
);

final RegExp _overrideCall = RegExp(
  r'(\w+Provider)\s*\.\s*overrideWith(?:Value)?\s*\(',
);

Set<String> _collectDeclaredTokens(Directory sharedDiDir) {
  final Set<String> names = <String>{};
  for (final File file in dartFilesUnder(sharedDiDir)) {
    if (file.path.endsWith('.g.dart')) {
      continue;
    }
    final String flat = _flatten(_stripComments(file.readAsStringSync()));
    for (final RegExp pattern in <RegExp>[
      _typeFirstDeclaration,
      _nameFirstDeclaration,
    ]) {
      for (final RegExpMatch match in pattern.allMatches(flat)) {
        names.add(match.group(1)!);
      }
    }
  }
  return names;
}

Set<String> _collectOverriddenTokens(Directory featuresDir) {
  final Set<String> names = <String>{};
  for (final File file in dartFilesUnder(featuresDir)) {
    if (file.path.endsWith('.g.dart')) {
      continue;
    }
    final String flat = _flatten(_stripComments(file.readAsStringSync()));
    for (final RegExpMatch match in _overrideCall.allMatches(flat)) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

String _flatten(String source) => source.replaceAll(RegExp(r'\s+'), ' ');

String _stripComments(String source) {
  final StringBuffer out = StringBuffer();
  String? quote;
  var lineComment = false;
  var blockComment = false;
  for (var i = 0; i < source.length; i++) {
    final String c = source[i];
    final String next = i + 1 < source.length ? source[i + 1] : '';
    if (lineComment) {
      if (c == '\n') {
        lineComment = false;
        out.write(c);
      }
      continue;
    }
    if (blockComment) {
      if (c == '*' && next == '/') {
        blockComment = false;
        i++;
      }
      continue;
    }
    if (quote != null) {
      out.write(c);
      if (c == r'\') {
        if (i + 1 < source.length) {
          out.write(next);
          i++;
        }
      } else if (c == quote) {
        quote = null;
      }
      continue;
    }
    if (c == '/' && next == '/') {
      lineComment = true;
      i++;
      continue;
    }
    if (c == '/' && next == '*') {
      blockComment = true;
      i++;
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      out.write(c);
      continue;
    }
    out.write(c);
  }
  return out.toString();
}
