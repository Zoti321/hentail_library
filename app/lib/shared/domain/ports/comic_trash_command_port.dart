/// 将 Comic 移入回收站的命令端口（#268）。
///
/// 生产实现位于 `features/comic_trash/di/comic_trash_command_port.dart`；
/// 测试可注入内存替身，因此该接缝有两个实现。
abstract class ComicTrashCommandPort {
  Future<void> trash(List<String> comicIds);
}
