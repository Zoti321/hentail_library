/// 打开 Reader（一次 Read session）的跨模块命令（#261a / ADR-0038）。
///
/// 跨 feature 请 import `features/reader/public.dart` 并调用 `openReader`；
/// [readerLaunchPortProvider] 在 shared/di 声明。
abstract class ReaderLaunchPort {
  Future<void> openComic({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  });
}
