part of 'domain_event.dart';

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
