import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart' as entity;
import 'package:hentai_library/domain/repository/tag_repo.dart';

class TagRepositoryImpl implements TagRepository {
  final LibraryTagDao _dao;

  TagRepositoryImpl(this._dao);

  @override
  Future<List<entity.Tag>> listAll() async {
    final rows = await _dao.listAll();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows.map((r) => entity.Tag(name: r.name)).toList();
  }

  @override
  Future<void> add(entity.Tag tag) => _dao.addTag(tag.name);

  @override
  Future<void> deleteByNames(List<String> names) async {
    await _dao.deleteByNames(names);
  }

  @override
  Future<void> rename(String oldName, String newName) =>
      _dao.renameTag(oldName, newName);
}
