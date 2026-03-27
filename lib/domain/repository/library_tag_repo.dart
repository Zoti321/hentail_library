import 'package:hentai_library/domain/entity/comic/library_tag.dart';

/// v2 Tag 仓储：独立于 Comic/Series 的“标签字典管理”。
abstract class LibraryTagRepository {
  Future<List<LibraryTag>> listAll();

  Future<void> add(LibraryTag tag);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);
}
