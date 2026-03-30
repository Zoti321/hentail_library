import 'package:hentai_library/domain/entity/comic/tag.dart';

/// v2 Tag 仓储：独立于 Comic/Series 的“标签字典管理”。
abstract class LibraryTagRepository {
  Future<List<Tag>> listAll();

  Future<void> add(Tag tag);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);
}
