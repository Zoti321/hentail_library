import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hentai_library/app/app.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await WindowManager.instance.ensureInitialized();

    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: true,
      );
      await windowManager.setMinimumSize(Size(800, 600));
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

  await initTray();
  LogManager.init();
  try {
    final logWriter = LogFileWriter(LogManager.instance);
    await logWriter.init();
  } catch (e, st) {
    LogManager.instance.handle(e, st, '文件日志初始化失败');
  }

  runApp(const MyApp());
}
