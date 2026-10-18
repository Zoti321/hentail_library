import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';

/// 全部作者列表。浏览筛选和已验证作者标记读这份完整字典。
final allAuthorsProvider = StreamProvider<List<Author>>((ref) {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  return ref.watch(authorRepoProvider).watchAll();
});
