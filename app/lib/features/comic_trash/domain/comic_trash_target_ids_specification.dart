/// Comic trash / purge 操作的目标 id 规约。
abstract final class ComicTrashTargetIdsSpecification {
  ComicTrashTargetIdsSpecification._();

  static List<String> normalize(Iterable<String> comicIds) {
    return comicIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
