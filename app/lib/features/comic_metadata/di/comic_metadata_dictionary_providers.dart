import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/features/comic_metadata/public/di/comic_metadata_repository_providers.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';

/// 全部作者列表。浏览筛选和已验证作者标记读这份完整字典。
final allAuthorsProvider = StreamProvider<List<Author>>((ref) {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  return ref.watch(authorRepoProvider).watchAll();
});

/// 全部标签列表。浏览筛选、溢出菜单和删除确认都读这份完整字典。
final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final tags = await ref.watch(tagRepoProvider).listAll();
  tags.sort((a, b) => a.name.compareTo(b.name));
  return tags;
});
