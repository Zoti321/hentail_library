/// 批量元数据写入后，失效字典类缓存（标签 / 作者 / 原作 / 角色）的端口（#267）。
///
/// 实现位于 `features/bootstrap/di/dictionary_invalidation_port.dart`：
/// 需要同时感知 named_metadata 与 library_browse 的 Provider，因此属于组合根。
abstract class DictionaryInvalidationPort {
  void invalidate({
    required bool tagsWritten,
    required bool authorsWritten,
    required bool parodiesWritten,
    required bool charactersWritten,
  });
}
