import 'package:hentai_library/features/reader/presentation/providers/reader_window_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_chrome_notifier.g.dart';

@Riverpod(keepAlive: true, name: 'readerChromeNotifierProvider')
class ReaderChromeNotifier extends _$ReaderChromeNotifier {
  @override
  bool build() => false;

  Future<void> setFullscreen(bool value) async {
    if (value) {
      // Hide in-app chrome before the OS resize. Otherwise the title bar can
      // remain visible through intermediate window sizes and overflow the shell.
      state = true;
      await ref.read(readerWindowFullscreenCommandProvider)(true);
      return;
    }

    await ref.read(readerWindowFullscreenCommandProvider)(false);
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
