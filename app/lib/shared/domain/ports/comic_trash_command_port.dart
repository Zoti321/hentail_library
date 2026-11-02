/// 将 Comic 移入回收站的命令（#261a）。
///
/// 跨 feature 请 import `features/comic_trash/public.dart`；
/// [comicTrashCommandPortProvider] 在 `features/comic_trash/di/` 声明；跨 feature 经 `comic_trash/public.dart`。
abstract class ComicTrashCommandPort {
  Future<void> trash(List<String> comicIds);
}
