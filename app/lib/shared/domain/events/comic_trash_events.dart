part of 'domain_event.dart';

/// 漫画已移入 Comic trash（ADR-0023）。
final class ComicsTrashed extends DomainEvent {
  const ComicsTrashed(this.comicIds);

  final List<String> comicIds;
}

/// 漫画已从 Comic trash 恢复。
final class ComicsRestored extends DomainEvent {
  const ComicsRestored(this.comicIds);

  final List<String> comicIds;
}
