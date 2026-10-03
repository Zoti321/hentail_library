import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';

class EmptyAuthorRepository implements AuthorRepository {
  const EmptyAuthorRepository();

  @override
  Future<List<Author>> listAll() async => const <Author>[];

  @override
  Stream<List<Author>> watchAll() =>
      Stream<List<Author>>.value(const <Author>[]);

  @override
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    return PagedResult<Author>(
      items: const <Author>[],
      totalCount: 0,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<Author> add(Author author) async => author;

  @override
  Future<void> deleteByNames(List<String> names) async {}

  @override
  Future<void> rename(String oldName, String newName) async {}

  @override
  Future<AuthorDetail?> getDetail({
    required int authorId,
    required bool showR18,
  }) async => null;

  @override
  Future<AuthorLink> addLink({
    required int authorId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    return (
      id: 1,
      platform: platform,
      url: url,
      platformDisplayName: platformDisplayName,
      sortKey: 0,
    );
  }

  @override
  Future<void> updateLink({
    required int linkId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {}

  @override
  Future<void> deleteLink({required int authorId, required int linkId}) async {}
}
