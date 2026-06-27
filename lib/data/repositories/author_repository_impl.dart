import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';

class AuthorRepositoryImpl implements AuthorRepository {
  AuthorRepositoryImpl(this._dao);

  final AuthorDao _dao;

  @override
  Future<List<Author>> listAll() async {
    final rows = await _dao.listAll();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows.map((r) => Author(name: r.name)).toList();
  }

  @override
  Stream<List<Author>> watchAll() {
    return _dao.watchAll().map(
      (rows) => rows.map((r) => Author(name: r.name)).toList(),
    );
  }

  @override
  Future<void> add(Author author) => _dao.addAuthor(author.name);

  @override
  Future<void> deleteByNames(List<String> names) => _dao.deleteByNames(names);

  @override
  Future<void> rename(String oldName, String newName) =>
      _dao.renameAuthor(oldName, newName);
}
