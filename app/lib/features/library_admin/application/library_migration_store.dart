enum LibraryPreferenceMigration { resourceFormats, autoScan }

abstract interface class LibraryMigrationStore {
  Future<bool> isCompleted(LibraryPreferenceMigration migration);
  Future<void> markCompleted(LibraryPreferenceMigration migration);
}
