import 'package:hentai_library/data/resources/local/database/dao/dao.dart';
import 'package:hentai_library/model/entity/comic/author.dart';

/// Author 仓储：独立于 Comic 的「作者字典管理」。
abstract class AuthorRepository {
  Future<List<Author>> listAll();

  /// 作者字典表变化时推送（含漫画侧 [replaceComicAuthors] 写入的 insertOrIgnore）。
  Stream<List<Author>> watchAll();

  Future<void> add(Author author);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);
}

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

