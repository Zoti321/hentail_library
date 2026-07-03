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
    final List<String> names = rust_author.listAllAuthorsFrb();
    return names.map((String n) => Author(name: n)).toList();
  }

  @override
  Stream<List<Author>> watchAll() {
    return rust_author.watchAuthorsFrb().map(
      (List<String> names) => names.map((String n) => Author(name: n)).toList(),
    );
  }

  @override
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    final rust_author.AuthorPagedNamesDto page = rust_author
        .fetchAuthorsPageFrb(
          request: rust.PageRequestDto(
            page: request.page,
            pageSize: request.pageSize,
          ),
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
    rust_author.addAuthorFrb(name: author.name);
  }

  @override
  Future<void> deleteByNames(List<String> names) async {
    rust_author.deleteAuthorsByNamesFrb(names: names);
  }

  @override
  Future<void> rename(String oldName, String newName) async {
    rust_author.renameAuthorFrb(oldName: oldName, newName: newName);
  }
}
