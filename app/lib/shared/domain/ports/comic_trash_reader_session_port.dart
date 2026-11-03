/// Trash / purge 前关闭指定 Comic 的阅读会话（shared seam，打破 public 环）。
abstract class ComicTrashReaderSessionPort {
  Future<void> closeComic(String comicId);
}
