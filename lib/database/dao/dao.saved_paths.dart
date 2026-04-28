part of 'dao.dart';

@DriftAccessor(tables: [SavedPaths])
class SavedPathDao extends DatabaseAccessor<AppDatabase>
    with _$SavedPathDaoMixin {
  SavedPathDao(super.db);

  Future<List<SavedPath>> getAll() => select(savedPaths).get();

  Stream<List<SavedPath>> watchAll() => select(savedPaths).watch().distinct();

  Future<int> insert(SavedPathsCompanion companion) {
    return into(savedPaths).insert(
      companion,
      mode: InsertMode.insertOrIgnore,
      onConflict: DoNothing(),
    );
  }

  Future<int> deleteRow(String path) {
    return (delete(savedPaths)..where((t) => t.rawPath.equals(path))).go();
  }
}
