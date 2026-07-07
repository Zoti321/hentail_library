/// 库级 revision 通知 seam（底层 SQLite data_version，覆盖 comic/series/metadata 写入）。
abstract class LibraryRevisionPort {
  Stream<void> watchRevision();
}
