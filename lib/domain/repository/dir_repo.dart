abstract class PathRepository {
  Future<List<String>> getAllPaths();

  Stream<List<String>> getPathsStream();

  Future<void> addPath(String path);

  Future<void> removePath(String path);
}
