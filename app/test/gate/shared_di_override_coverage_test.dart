import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'lib_layout_scan_helpers.dart';

/// `shared/presentation/providers` 的 token 只声明、不实现：默认抛 `UnimplementedError`，
/// 必须由 `composition/**` override 填实。
///
/// 漏注入的 token 只在运行期（某个页面首次 `ref.read` 时）才炸，且报错点
/// 远离改动点。本门禁把它提前到 CI。
///
/// 局限：只校验「声明 ⊆ 应用内某处被 override」，不追溯该 override 所在的
/// 函数是否真的被组合根（`appProviderOverrides`）收集。组合根漏收集由
/// `test/composition` 的运行时用例兜底。
void main() {
  late Directory libDir;
  late Directory sharedDiDir;
  late Directory featuresDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    sharedDiDir = Directory(
      p.join(libDir.path, 'shared', 'presentation', 'providers'),
    );
    featuresDir = Directory(libDir.path);
  });

  test('injection scanner covers function/query/stream declarations and autoDispose families', () {
    expect(
      _declaredTokenNames("""
final Provider<Future<void> Function(String)> saveCommandProvider = requiredProvider('saveCommandProvider');
final Provider<Future<int?> Function(String)> resumeQueryProvider = requiredProvider('resumeQueryProvider');
final StreamProvider<Map<String, int>> progressProvider = StreamProvider((ref) => stream);
final countsProvider = StreamProvider.autoDispose.family<Counts, bool>((ref, enabled) => stream);
// final Provider<void> ignoredProvider = requiredProvider('ignoredProvider');
"""),
      {
        'saveCommandProvider',
        'resumeQueryProvider',
        'progressProvider',
        'countsProvider',
      },
    );
  });

  test('shared/presentation/providers 每个注入 token 至少有一处 overrideWith', () {
    expect(
      sharedDiDir.existsSync(),
      isTrue,
      reason: 'missing lib/shared/presentation/providers',
    );

    final Set<String> declared = _collectDeclaredTokens(sharedDiDir);
    expect(
      declared,
      isNotEmpty,
      reason: 'shared/presentation/providers 未采集到任何 token，扫描规则可能已失效',
    );

    final Set<String> overridden = _collectOverriddenTokens(featuresDir);
    expect(
      overridden,
      isNotEmpty,
      reason: 'features/ 未采集到任何 overrideWith，扫描规则可能已失效',
    );

    final List<String> missing = declared.difference(overridden).toList()
      ..sort();
    expect(
      missing,
      isEmpty,
      reason:
          '以下 shared/presentation/providers token 没有任何 overrideWith/overrideWithValue：\n'
          '${missing.join('\n')}\n'
          '请在 composition/** 补注入。',
    );
  });
}

/// 类型在前的声明：`final Provider<T> name = ...` / `final FutureProviderFamily<T, P> name = ...`。
final RegExp _typeFirstDeclaration = RegExp(
  r'final\s+(?:Provider|FutureProvider|StreamProvider|ProviderFamily|FutureProviderFamily|StreamProviderFamily)(?:\.(?:autoDispose|family))*\s*<[^=]*?>\s*(\w+Provider)\s*=',
);

/// 名称在前的声明：`final name = FutureProvider.family<T, P>(...)`。
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
    names.addAll(_declaredTokenNames(file.readAsStringSync()));
  }
  return names;
}

Set<String> _declaredTokenNames(String source) {
  final flat = _flatten(_stripComments(source));
  return {
    for (final pattern in [_typeFirstDeclaration, _nameFirstDeclaration])
      for (final match in pattern.allMatches(flat)) match.group(1)!,
  };
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

/// 去掉行注释与块注释；跳过字符串字面量内的 `//` / `/*`。
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
      if (c == '\\' && next.isNotEmpty) {
        out.write(next);
        i++;
        continue;
      }
      if (c == quote) {
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
