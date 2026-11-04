/// Comic trash 状态变更后的领域事件。
sealed class ComicTrashDomainEvent {
  const ComicTrashDomainEvent();
}

final class ComicsTrashed extends ComicTrashDomainEvent {
  const ComicsTrashed(this.comicIds);

  final List<String> comicIds;
}

final class ComicsRestored extends ComicTrashDomainEvent {
  const ComicsRestored(this.comicIds);

  final List<String> comicIds;
}

final class ComicsPurged extends ComicTrashDomainEvent {
  const ComicsPurged({required this.succeeded, required this.failed});

  final int succeeded;
  final int failed;
}
