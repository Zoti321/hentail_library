abstract class DirectoryRepository {
  Future<List<String>> getAllDirs();

  Stream<List<String>> getDirsStream();

  Future<void> addDir(String path);

  Future<void> removeDir(String path);
}

