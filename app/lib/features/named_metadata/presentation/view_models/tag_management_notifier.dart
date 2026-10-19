import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';

/// 全部标签列表。浏览筛选、溢出菜单和删除确认都读这份完整字典。
final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  final tags = await ref.watch(tagRepoProvider).listAll();
  tags.sort((a, b) => a.name.compareTo(b.name));
  return tags;
});
