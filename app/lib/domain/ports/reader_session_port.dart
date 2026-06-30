/// Library sync 后清理阅读会话缓存的 seam。
abstract class ReaderSessionPort {
  Future<void> clear();
}
