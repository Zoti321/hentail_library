/// 将 Comic 移入回收站的命令（#261a）。
///
/// 跨 feature 请 import `features/comic_trash/public.dart`；
/// [comicTrashCommandPortProvider] 在 `shared/di/library_command_providers.dart` 声明。
abstract class ComicTrashCommandPort {
  Future<void> trash(List<String> comicIds);
}
