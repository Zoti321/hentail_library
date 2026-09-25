import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:path/path.dart' as p;

/// 覆盖 cdylib 路径；未设置时在 `core/target/{debug,release}/` 下查找。
const String hentaiFlutterLibEnv = 'HENTAI_FLUTTER_LIB';

String _libraryFileName() {
  if (Platform.isWindows) return 'hentai_flutter.dll';
  if (Platform.isMacOS) return 'libhentai_flutter.dylib';
  return 'libhentai_flutter.so';
}

/// 定位宿主平台的 `hentai_flutter` 动态库（`flutter test` 的 cwd 为 `app/`）。
String resolveHentaiFlutterLibrary() {
  final String? override = Platform.environment[hentaiFlutterLibEnv];
  if (override != null && override.isNotEmpty) return override;

  final String targetDir = p.normalize(
    p.join(Directory.current.path, '..', 'core', 'target'),
  );
  for (final String profile in <String>['debug', 'release']) {
    final String candidate = p.join(targetDir, profile, _libraryFileName());
    if (File(candidate).existsSync()) return candidate;
  }
  throw StateError(
    '找不到 hentai_flutter 动态库（$targetDir）。'
    '先运行 `cargo build --manifest-path core/Cargo.toml -p hentai_flutter`，'
    '或设置 $hentaiFlutterLibEnv。',
  );
}

/// 以真实 cdylib 初始化 [RustLib]；同一测试进程内重复调用无副作用。
Future<void> initRustLibForWireTest() async {
  if (RustLib.instance.initialized) return;
  await RustLib.init(
    externalLibrary: ExternalLibrary.open(resolveHentaiFlutterLibrary()),
  );
}
