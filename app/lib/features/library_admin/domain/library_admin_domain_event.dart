import 'package:hentai_library/features/library_admin/domain/library_change.dart';

/// Library 写入后的领域事件（metadata refresh / sync 汇总）。
sealed class LibraryAdminDomainEvent {
  const LibraryAdminDomainEvent();
}

final class LibraryMetadataPersisted extends LibraryAdminDomainEvent {
  const LibraryMetadataPersisted(this.change);

  final LibraryChange change;
}
