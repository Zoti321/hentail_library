part of 'domain_event.dart';

/// 目录（catalog）变更的来源，仅用于诊断与日志。
enum CatalogChangeSource { sync, metadataRefresh, libraryAdmin, comicTrash }

/// 库 / 漫画集合已变化，订阅方应重读 catalog（ADR-0039）。
///
/// 与 SQLite `data_version` 流（[LibraryRevisionPort]）的区别：本事件覆盖
/// stream 可能已错过的、由应用自身写入触发的变更。
final class LibraryCatalogChanged extends DomainEvent {
  const LibraryCatalogChanged([
    this.source = CatalogChangeSource.libraryAdmin,
  ]);

  final CatalogChangeSource source;
}

/// Comic 用户元数据已落库（comic / library_admin 的写入用例发布）。
///
/// 字典标志表示本次写入是否可能新增全局 Tag / Author / Parody / Character 条目；
/// 无字段变化的重存不得发布本事件。
final class ComicMetadataPersisted extends DomainEvent {
  const ComicMetadataPersisted({
    this.tagsWritten = false,
    this.authorsWritten = false,
    this.parodiesWritten = false,
    this.charactersWritten = false,
  });

  final bool tagsWritten;
  final bool authorsWritten;
  final bool parodiesWritten;
  final bool charactersWritten;

  bool get dictionariesWritten =>
      tagsWritten || authorsWritten || parodiesWritten || charactersWritten;
}
