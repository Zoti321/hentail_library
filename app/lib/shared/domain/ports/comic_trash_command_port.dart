/// 将 Comic 移入回收站的命令（#261a）。
///
/// 跨 feature 请 import `features/comic_trash/public.dart`；
/// [comicTrashCommandPortProvider] 在 `shared/di/data_providers.dart` 声明。
///
/// ADR-0045 可达性豁免：唯一跨模块消费者 `comic`，而 `comic_trash` 已 import
/// `features/comic/public`；若迁入 comic_trash 会形成 public 环，故 Port 与
/// token 留在 shared。
abstract class ComicTrashCommandPort {
  Future<void> trash(List<String> comicIds);
}
