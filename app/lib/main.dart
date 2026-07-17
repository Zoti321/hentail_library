import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hentai_library/core/image/image_cache_config.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/logging/app_logging.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/frb_zone_guard.dart';
import 'package:hentai_library/src/rust/api/comic.dart';
import 'package:hentai_library/src/rust/api/logging.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/features/shell/views/app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Paint a first frame immediately so Android splash is not stuck while
    // loading the Rust cdylib (can be large / slow on emulators).
    final Future<void> prepare = _prepareApp();
    runApp(_BootstrapApp(prepare: prepare));
  }, handleUncaughtFrbZoneError);
}

Future<void> _prepareApp() async {
  try {
    await configureAppLogging();
  } catch (e, st) {
    debugPrint('文件日志初始化失败: $e\n$st');
  }

  await RustLib.init();

  try {
    final appDataDir = await getApplicationSupportDirectory();
    guardFrbSync(
      () => configureRustLogFrb(appDataDir: appDataDir.path),
      fallbackMessage: 'Rust 日志初始化失败',
    );
    guardFrbSync(
      () => initDbFrb(appDataDir: appDataDir.path, dbFileName: 'my_database'),
      fallbackMessage: '数据库初始化失败',
    );
  } catch (e, st) {
    logError(AppLog.dataFrb(), 'Rust 初始化失败', e, st);
  }

  configureGlobalImageCache();

  if (isDesktop) {
    await _initWindow();
  }
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp({required this.prepare});

  final Future<void> prepare;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: prepare,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '启动失败：${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return const MyApp();
      },
    );
  }
}

Future<void> _initWindow() async {
  await WindowManager.instance.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    await windowManager.setMinimumSize(
      const Size(
        AppLayoutBreakpoints.minWindowWidth,
        AppLayoutBreakpoints.minWindowHeight,
      ),
    );
    await windowManager.center();
    await windowManager.show();
    await windowManager.setPreventClose(true);
    await windowManager.setSkipTaskbar(false);
  });

  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.solid,
    color: Colors.white,
    dark: false,
  );
}
