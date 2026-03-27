import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/domain/entity/v2/library_tag.dart' as entity;
import 'package:hentai_library/domain/repository/v2/library_tag_repo.dart';

class LibraryTagRepositoryImpl implements LibraryTagRepository {
  final LibraryTagDao _dao;

  LibraryTagRepositoryImpl(this._dao);

  @override
  Future<List<entity.LibraryTag>> listAll() async {
    final rows = await _dao.listAll();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows.map((r) => entity.LibraryTag(name: r.name)).toList();
  }

  @override
  Future<void> add(entity.LibraryTag tag) => _dao.addTag(tag.name);

  @override
  Future<void> deleteByNames(List<String> names) async {
    await _dao.deleteByNames(names);
  }

  @override
  Future<void> rename(String oldName, String newName) =>
      _dao.renameTag(oldName, newName);
}

