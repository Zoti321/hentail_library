import 'package:hentai_library/data/resources/local/database/dao/dao.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';

/// Tag 仓储：独立于 Comic/Series 的“标签字典管理”。
abstract class TagRepository {
  Future<List<Tag>> listAll();

  Future<void> add(Tag tag);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);
}

class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._dao);

  final TagDao _dao;

  @override
  Future<List<Tag>> listAll() async {
    final rows = await _dao.listAll();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows.map((r) => Tag(name: r.name)).toList();
  }

  @override
  Future<void> add(Tag tag) => _dao.addTag(tag.name);

  @override
  Future<void> deleteByNames(List<String> names) async {
    await _dao.deleteByNames(names);
  }

  @override
  Future<void> rename(String oldName, String newName) =>
      _dao.renameTag(oldName, newName);
}

