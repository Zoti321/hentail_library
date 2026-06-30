import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hentai_library/core/image/image_quality_policy.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/src/rust/api/comic.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:hentai_library/ui/features/shell/views/app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  try {
    final appDataDir = await getApplicationSupportDirectory();
    initDbFrb(appDataDir: appDataDir.path, dbFileName: 'my_database');
  } catch (e, st) {
    debugPrint('Rust init_db 失败: $e\n$st');
  }

  _initImageQualityPolicy();

  if (isDesktop) {
    await _initWindow();
  }

  LogManager.init();
  try {
    final logWriter = LogFileWriter(LogManager.instance);
    await logWriter.init();
  } catch (e, st) {
    LogManager.instance.handle(e, st, '文件日志初始化失败');
  }

  runApp(const MyApp());
}

void _initImageQualityPolicy() {
  final ImageQualityPolicy imageQualityPolicy = configureImageQualityPolicy();
  final ImageCache imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = imageQualityPolicy.imageCacheMaxEntries;
  imageCache.maximumSizeBytes = imageQualityPolicy.imageCacheMaxBytes;
}

Future<void> _initWindow() async {
  await WindowManager.instance.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    await windowManager.setMinimumSize(Size(1024, 576));
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
