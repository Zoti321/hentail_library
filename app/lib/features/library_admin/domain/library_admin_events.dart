import 'package:hentai_library/features/library_admin/domain/library_change.dart';

/// Library 写入后的领域事件（metadata refresh / sync 汇总）。
sealed class LibraryAdminEvent {
  const LibraryAdminEvent();
}

final class LibraryMetadataPersisted extends LibraryAdminEvent {
  const LibraryMetadataPersisted(this.change);

  final LibraryChange change;
}
