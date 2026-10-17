/// 书库写入事件（#268）：写入方只声明"发生了什么"，不关心谁需要刷新。
///
/// 订阅方通过 `libraryChangeBusProvider` 的 revision 自行决定失效与重取。
class LibraryChange {
  const LibraryChange({
    this.tagsWritten = false,
    this.authorsWritten = false,
    this.parodiesWritten = false,
    this.charactersWritten = false,
    this.metadataSaved = false,
  });

  final bool tagsWritten;
  final bool authorsWritten;
  final bool parodiesWritten;
  final bool charactersWritten;

  /// 元数据已落库（用于自动备份调度）。
  final bool metadataSaved;

  bool get dictionariesWritten =>
      tagsWritten || authorsWritten || parodiesWritten || charactersWritten;
}
