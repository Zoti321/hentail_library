/// Comic trash 状态变更后的领域事件。
sealed class ComicTrashEvent {
  const ComicTrashEvent();
}

final class ComicsTrashed extends ComicTrashEvent {
  const ComicsTrashed(this.comicIds);

  final List<String> comicIds;
}

final class ComicsRestored extends ComicTrashEvent {
  const ComicsRestored(this.comicIds);

  final List<String> comicIds;
}

final class ComicsPurged extends ComicTrashEvent {
  const ComicsPurged({required this.succeeded, required this.failed});

  final int succeeded;
  final int failed;
}
