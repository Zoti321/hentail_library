abstract class PathRepository {
  Future<List<String>> getAll();

  Stream<List<String>> watch();

  Future<void> add(String path);

  Future<void> remove(String path);
}
