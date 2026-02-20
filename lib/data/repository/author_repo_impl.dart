import 'package:hentai_library/data/resources/local/database/dao/dao.dart';
import 'package:hentai_library/domain/entity/comic/author.dart' as entity;
import 'package:hentai_library/domain/repository/author_repo.dart';

class AuthorRepositoryImpl implements AuthorRepository {
  AuthorRepositoryImpl(this._dao);

  final AuthorDao _dao;

  @override
  Future<List<entity.Author>> listAll() async {
    final rows = await _dao.listAll();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows.map((r) => entity.Author(name: r.name)).toList();
  }

  @override
  Stream<List<entity.Author>> watchAll() {
    return _dao.watchAll().map(
      (rows) => rows.map((r) => entity.Author(name: r.name)).toList(),
    );
  }

  @override
  Future<void> add(entity.Author author) => _dao.addAuthor(author.name);

  @override
  Future<void> deleteByNames(List<String> names) => _dao.deleteByNames(names);

  @override
  Future<void> rename(String oldName, String newName) =>
      _dao.renameAuthor(oldName, newName);
}
