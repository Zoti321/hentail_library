import 'package:hentai_library/core/util/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'reader_fullscreen_controller.g.dart';

@Riverpod(keepAlive: true)
class ReaderFullscreenController extends _$ReaderFullscreenController {
  @override
  bool build() => false;

  Future<void> setFullscreen(bool value) async {
    if (value) {
      // Hide in-app chrome before the OS resize. Otherwise the title bar can
      // remain visible through intermediate window sizes and overflow the shell.
      state = true;
      if (supportsDesktopWindowChrome) {
        await windowManager.setFullScreen(true);
      }
      return;
    }

    if (supportsDesktopWindowChrome) {
      await windowManager.setFullScreen(false);
    }
    state = false;
  }

  Future<void> toggleFullscreen() async {
    await setFullscreen(!state);
  }

  Future<void> exitFullscreenIfNeeded() async {
    if (!state) {
      return;
    }
    await setFullscreen(false);
  }
}
