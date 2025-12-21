import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
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
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    final int totalCount = await _dao.countAllAuthors();
    if (totalCount <= 0) {
      return PagedResult<Author>(
        items: const <Author>[],
        totalCount: 0,
        page: 1,
        pageSize: request.pageSize,
      );
    }
    final int totalPages =
        (totalCount + request.pageSize - 1) ~/ request.pageSize;
    int effectivePage = request.page;
    if (effectivePage > totalPages) {
      effectivePage = totalPages;
    }
    final int offset = (effectivePage - 1) * request.pageSize;
    final rows = await _dao.fetchAuthorsPage(
      limit: request.pageSize,
      offset: offset,
    );
    return PagedResult<Author>(
      items: rows.map((r) => Author(name: r.name)).toList(),
      totalCount: totalCount,
      page: effectivePage,
      pageSize: request.pageSize,
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
