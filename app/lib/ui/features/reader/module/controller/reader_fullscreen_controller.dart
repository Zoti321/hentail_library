import 'package:hentai_library/core/util/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'reader_fullscreen_controller.g.dart';

@Riverpod(keepAlive: true)
class ReaderFullscreenController extends _$ReaderFullscreenController {
  @override
  bool build() => false;

  Future<void> setFullscreen(bool value) async {
    if (isDesktop) {
      await windowManager.setFullScreen(value);
    }
    state = value;
  }

  Future<void> toggleFullscreen() async {
    await setFullscreen(!state);
  }

  Future<void> exitFullscreenIfNeeded() async {
    if (!state) {
      return;
    }
    state = false;
    if (isDesktop) {
      await windowManager.setFullScreen(false);
    }
  }
}
