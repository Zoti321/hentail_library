import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

class AuthorRepositoryImpl implements AuthorRepository {
  const AuthorRepositoryImpl();

  @override
  Future<List<Author>> listAll() async {
    final List<String> names = guardFrbSync(
      rust_author.listAllAuthorsFrb,
      fallbackMessage: '读取作者列表失败',
    );
    return names.map((String n) => Author(name: n)).toList();
  }

  @override
  Stream<List<Author>> watchAll() {
    return guardFrbStream(
      () => rust_author.watchAuthorsFrb().map(
        (List<String> names) =>
            names.map((String n) => Author(name: n)).toList(),
      ),
      fallbackMessage: '监听作者列表失败',
    );
  }

  @override
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    final rust_author.AuthorPagedNamesDto page = guardFrbSync(
      () => rust_author.fetchAuthorsPageFrb(
        request: rust.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: '读取作者分页失败',
    );
    return PagedResult<Author>(
      items: page.items.map((String n) => Author(name: n)).toList(),
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<void> add(Author author) async {
    guardFrbSync(
      () => rust_author.addAuthorFrb(name: author.name),
      fallbackMessage: '添加作者失败',
    );
  }

  @override
  Future<void> deleteByNames(List<String> names) async {
    guardFrbSync(
      () => rust_author.deleteAuthorsByNamesFrb(names: names),
      fallbackMessage: '删除作者失败',
    );
  }

  @override
  Future<void> rename(String oldName, String newName) async {
    guardFrbSync(
      () => rust_author.renameAuthorFrb(oldName: oldName, newName: newName),
      fallbackMessage: '重命名作者失败',
    );
  }
}
