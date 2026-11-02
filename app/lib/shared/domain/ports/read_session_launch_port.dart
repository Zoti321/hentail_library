/// 打开阅读会话的跨模块命令（#261a）。
///
/// 跨 feature 请 import `features/read_session/public.dart`；
/// [readSessionLaunchPortProvider] 在 shared/di 声明。
abstract class ReadSessionLaunchPort {
  Future<void> openComic({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  });
}
