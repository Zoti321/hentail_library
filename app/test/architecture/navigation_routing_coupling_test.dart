import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

/// 导航与路由耦合门禁（ADR-0043）：
/// feature / shared 只下达 [AppNavigator] 意图，go_router 仅存在于宿主路由层。
void main() {
  late Directory libDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test('go_router import 仅允许出现在路由集成白名单（shrink-only）', () {
    final Set<String> found = <String>{};
    for (final File file in dartFilesUnder(libDir)) {
      if (_goRouterImportRe.hasMatch(file.readAsStringSync())) {
        found.add(_libRelative(libDir, file));
      }
    }
    expect(
      found,
      unorderedEquals(_routerIntegrationAllowlist),
      reason:
          'go_router 是宿主路由实现细节，不得扩散到 feature / shared UI。\n'
          '新增依赖请改为 AppNavigator 意图；如确属路由集成层，更新白名单需评审。\n'
          '当前发现：\n${(found.toList()..sort()).join('\n')}',
    );
  });

  test('feature 层不直接调用 GoRouter / BuildContext 路由 API', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(
      Directory(p.join(libDir.path, 'features')),
    )) {
      final String rel = _libRelative(libDir, file);
      if (_routerIntegrationAllowlist.contains(rel)) {
        continue;
      }
      final String source = file.readAsStringSync();
      if (_routerApiRe.hasMatch(source)) {
        offenders.add(rel);
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'feature 只能 ref.read(appNavigatorProvider).xxx() 下达导航意图，'
          '不得直接 context.go / context.push / GoRouter.of：\n'
          '${offenders.join('\n')}',
    );
  });

  test('导航调用不得内联 location 字面量', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(libDir)) {
      final String rel = _libRelative(libDir, file);
      if (isGeneratedDartFile(rel)) {
        continue;
      }
      if (_inlineLocationRe.hasMatch(file.readAsStringSync())) {
        offenders.add(rel);
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          '导航路径必须来自 AppRoutes / AppNavigator，禁止内联 "/xxx"：\n'
          '${offenders.join('\n')}',
    );
  });

  test('不再暴露 GoRouter 具体类型的 DI token', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(
      Directory(p.join(libDir.path, 'shared', 'di')),
    )) {
      final String source = file.readAsStringSync();
      if (_routerTypeTokenRe.hasMatch(source)) {
        offenders.add(_libRelative(libDir, file));
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'shared/di 只声明 AppNavigator 契约，不暴露 GoRouter：\n'
          '${offenders.join('\n')}',
    );
  });
}

/// 路由集成层（host）：唯一允许 import go_router 的位置。
const Set<String> _routerIntegrationAllowlist = <String>{
  'features/bootstrap/presentation/views/routing/app_router.dart',
  'features/bootstrap/presentation/views/routing/go_router_app_navigator.dart',
  'features/bootstrap/presentation/views/routing/shared_content_routes.dart',
  'design-system/motion/catalog_detail_page.dart',
  'design-system/motion/desktop_page_transition.dart',
  'design-system/motion/shared_axis_route.dart',
};

String _libRelative(Directory libDir, File file) {
  return p.posix.normalize(
    p.relative(file.path, from: libDir.path).replaceAll(r'\', '/'),
  );
}

final RegExp _goRouterImportRe = RegExp(
  r'''import\s+['"]package:go_router/go_router\.dart['"]''',
);

/// 直接路由 API（feature 视为耦合边）。
final RegExp _routerApiRe = RegExp(
  r'''(?:context|GoRouter)(?:\.\s*|\s*\.\s*)(?:go|push|pushNamed|goNamed|replace|replaceNamed|pushReplacement|pop|canPop)\s*\(|GoRouter\.of\s*\(''',
);

/// `nav.go('/literal')` / `nav.push('/literal')` 等内联路径。
final RegExp _inlineLocationRe = RegExp(
  r'''\.(?:go|push|pushNamed|goNamed|replace|replaceNamed|pushReplacement|goLocation|replaceLocation)\s*\(\s*['"]/''',
);

/// `Provider<GoRouter>` / `GoRouter` 作为 shared/di 契约类型。
final RegExp _routerTypeTokenRe = RegExp(r'''GoRouter''');
